require "fileutils"
require "json"
require_relative "command"

module DependencySkillsEval
  class OpenCode
    CONFIG = {
      "autoupdate" => false,
      "share" => "disabled",
      "snapshot" => false,
      "plugin" => [],
      "instructions" => [],
      "permission" => {
        "*" => "deny",
        "read" => "allow", "glob" => "allow", "grep" => "allow", "skill" => "allow",
        "bash" => {
          "*" => "deny",
          "git show *" => "allow", "git log *" => "allow", "git diff *" => "allow",
          "git status*" => "allow", "git rev-parse *" => "allow", "git ls-tree *" => "allow"
        }
      }
    }.freeze

    def initialize(executable:, provider_config: {}, auth_path: nil)
      @executable = executable
      @provider_config = provider_config
      @auth_path = auth_path
    end

    def prepare_home(home)
      config_directory = File.join(home, "config", "opencode")
      FileUtils.mkdir_p(config_directory)
      File.write(File.join(config_directory, "opencode.json"),
        JSON.pretty_generate(CONFIG.merge(@provider_config)), mode: "w", perm: 0o600)

      return unless @auth_path

      data_directory = File.join(home, "data", "opencode")
      FileUtils.mkdir_p(data_directory)
      destination = File.join(data_directory, "auth.json")
      FileUtils.copy_file(@auth_path, destination)
      File.chmod(0o600, destination)
    end

    def environment(home, workspace)
      overrides = ENV.keys.grep(/^OPENCODE_/).to_h { |key| [key, nil] }
      overrides.merge(
        "HOME" => home,
        "XDG_CONFIG_HOME" => File.join(home, "config"),
        "XDG_DATA_HOME" => File.join(home, "data"),
        "XDG_CACHE_HOME" => File.join(home, "cache"),
        "XDG_STATE_HOME" => File.join(home, "state"),
        "OPENCODE_CONFIG_DIR" => File.join(home, "config", "opencode"),
        "OPENCODE_DISABLE_CLAUDE_CODE" => "true",
        "OPENCODE_DISABLE_AUTOUPDATE" => "true",
        "OPENCODE_DISABLE_LSP_DOWNLOAD" => "true",
        "OPENCODE_DISABLE_TERMINAL_TITLE" => "true",
        "PWD" => workspace,
        "NO_COLOR" => "1"
      )
    end

    def preflight(home, workspace, skill_names)
      options = {directory: workspace, environment: environment(home, workspace)}
      version = Command.capture(@executable, "--version", **options).strip
      skills = JSON.parse(Command.capture(@executable, "--pure", "debug", "skill", **options))
      unless skills.is_a?(Array) && skills.map { |skill| skill.fetch("name") }.sort == skill_names.sort
        raise "OpenCode must discover exactly the eval skills; check isolation and harness version"
      end

      skills.each do |skill|
        expected = File.join(workspace, ".opencode", "skills", skill.fetch("name"), "SKILL.md")
        unless File.realpath(skill.fetch("location")) == File.realpath(expected)
          raise "Eval skill shadowed: #{skill.fetch("name")}"
        end
      end

      config = JSON.parse(Command.capture(@executable, "--pure", "debug", "config", **options))
      unless Array(config["instructions"]).empty? && Array(config["plugin"]).empty?
        raise "Unexpected instructions or plugins in resolved OpenCode config"
      end

      {"version" => version, "skills" => skills.map { |skill| skill.slice("name", "location") },
       "permission" => config["permission"]}
    end

    def run(target:, home:, workspace:, prompt:, timeout:, artifacts:)
      arguments = [@executable, "--pure", "run", "--format", "json", "--agent", "build",
        "--model", target.fetch("model")]
      arguments.concat(["--variant", target["variant"]]) if target["variant"]
      arguments.concat(["--title", "dependency-loading-eval", "--", prompt])
      File.write(File.join(artifacts, "invocation.json"), JSON.pretty_generate(arguments))
      Command.record(arguments, directory: workspace, environment: environment(home, workspace),
        timeout: timeout, trace_path: File.join(artifacts, "trace.jsonl"),
        stderr_path: File.join(artifacts, "stderr.log"))
    end

    # Convert harness events into the small contract consumed by TraceScorer.
    def normalize_trace(path)
      events = []
      errors = []
      seen_tools = {}

      File.foreach(path).with_index(1) do |line, line_number|
        next if line.strip.empty?

        begin
          record = JSON.parse(line)
          raise ArgumentError, "expected an object" unless record.is_a?(Hash)

          event = normalize_event(record)
          next unless event

          if event["kind"] == "tool" && event["call_id"]
            key = [event["session_id"], event["call_id"], event["status"]]
            next if seen_tools[key]

            seen_tools[key] = true
          end
          events << event
        rescue JSON::ParserError, KeyError, ArgumentError, TypeError => error
          errors << "Trace line #{line_number}: #{error.message}"
        end
      end

      {"events" => events, "errors" => errors}
    end

    def normalize_event(record)
      session_id = record.fetch("sessionID")
      raise ArgumentError, "invalid session ID" unless session_id.is_a?(String) && !session_id.empty?

      event = {"session_id" => session_id}
      case record.fetch("type")
      when "tool_use"
        part = record.fetch("part")
        raise ArgumentError, "expected tool part object" unless part.is_a?(Hash)

        state = part.fetch("state")
        raise ArgumentError, "expected tool state object" unless state.is_a?(Hash)
        unless part["tool"].is_a?(String) && state["input"].is_a?(Hash)
          raise ArgumentError, "invalid tool name or input"
        end
        unless %w[completed error].include?(state.fetch("status"))
          raise ArgumentError, "unexpected tool status"
        end
        if state["status"] == "completed" && !state["output"].is_a?(String)
          raise ArgumentError, "completed tool output must be a string"
        end
        event.merge("kind" => "tool", "tool" => part.fetch("tool"),
          "call_id" => part["callID"] || part["id"], "status" => state["status"],
          "input" => state.fetch("input"), "output" => state.fetch("output", ""))
      when "text"
        part = record.fetch("part")
        unless part.is_a?(Hash) && part["text"].is_a?(String)
          raise ArgumentError, "invalid text part"
        end
        event.merge("kind" => "text", "text" => part["text"])
      when "step_finish"
        part = record.fetch("part")
        unless part.is_a?(Hash) && part["reason"].is_a?(String)
          raise ArgumentError, "invalid completion part"
        end
        event.merge("kind" => "finish", "reason" => part["reason"])
      when "error"
        event.merge("kind" => "error", "message" => JSON.generate(record.fetch("error")))
      when "step_start", "reasoning"
        nil
      else
        raise ArgumentError, "unknown event type: #{record["type"]}"
      end
    end
  end
end
