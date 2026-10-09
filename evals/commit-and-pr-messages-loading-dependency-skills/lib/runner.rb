require "digest"
require "fileutils"
require "json"
require "tmpdir"
require "time"
require_relative "opencode"
require_relative "trace_scorer"

module DependencySkillsEval
  class Runner
    def initialize(options)
      @options = options
      @directory = File.expand_path("..", __dir__)
      @suite = JSON.parse(File.read(options.fetch(:suite)))
      @targets = options.fetch(:targets)
      @repetitions = options[:repetitions] || @suite.fetch("repetitions")
      @timeout = options[:timeout] || @suite.fetch("timeout_seconds")
      @output = options.fetch(:output)
      @results = []
      @skill_contents = TraceScorer::SKILLS.to_h do |name|
        [name, File.read(File.join(options.fetch(:skills_root), name, "SKILL.md"))]
      end
      @policy = File.read(File.join(@directory, "../../permanent-principles/escalation-policy.md"))
      @prompt_template = File.read(File.join(@directory, "prompts", "#{options.fetch(:mode)}.md"))
      bodies = @skill_contents.transform_values { |content| content.sub(/\A---\r?\n.*?\r?\n---\r?\n/m, "").strip }
      @scorer = TraceScorer.new(bodies)
      @harness = OpenCode.new(executable: options.fetch(:executable),
        provider_config: options.fetch(:provider_config), auth_path: options[:auth_path])
      validate
    end

    def run
      FileUtils.mkdir_p(File.dirname(@output))
      Dir.mkdir(@output)
      @scratch = Dir.mktmpdir("dependency-skills-eval-")
      begin
        save_manifest
        repository = prepare_repository
        save_cases(repository)
        preflight_workspace = prepare_workspace(repository, "preflight", commits.first)
        home = prepare_home("preflight")
        preflight = @harness.preflight(home, preflight_workspace, TraceScorer::SKILLS)
        save_json("preflight.json", preflight)
        puts "OpenCode #{preflight.fetch("version")}: both local skills discovered."
        puts "#{planned_trials} trials planned. Results: #{@output}"
        return 0 if @options[:prepare_only]

        FileUtils.mkdir_p(File.join(@output, "trials"))
        run_trials(repository)
        (@results.any? { |result| result["status"] == "invalid" }) ? 2 : 0
      rescue Interrupt
        save_summary(interrupted: true) unless @options[:prepare_only]
        warn "Interrupted; completed trials and available raw traces retained."
        130
      rescue => error
        save_json("run-error.json", {"class" => error.class.name, "message" => error.message})
        raise
      ensure
        FileUtils.remove_entry(@scratch)
      end
    end

    def commits
      @suite.fetch("commits")
    end

    def planned_trials
      commits.size * @targets.size * @repetitions
    end

    def validate
      unless commits.is_a?(Array) && !commits.empty? && commits.uniq == commits &&
          commits.all? { |commit| commit.is_a?(String) && commit.match?(/\A[0-9a-f]{40}\z/) }
        raise ArgumentError, "Suite must contain unique full commit SHAs"
      end
      unless [@repetitions, @timeout].all? { |value| value.is_a?(Integer) && value.positive? }
        raise ArgumentError, "Repetitions and timeout must be positive integers"
      end
      raise ArgumentError, "Prompt is missing {{commit}}" unless @prompt_template.include?("{{commit}}")
    end

    def prepare_repository
      return @options[:repository] if @options[:repository]

      repository = File.join(@scratch, "source.git")
      Command.capture("git", "clone", "--quiet", "--bare", @suite.fetch("repository"), repository,
        directory: @scratch)
      repository
    end

    def prepare_workspace(repository, id, commit)
      workspace = File.join(@scratch, id, "repository")
      FileUtils.mkdir_p(File.dirname(workspace))
      Command.capture("git", "clone", "--quiet", "--no-hardlinks", "--no-checkout", repository, workspace,
        directory: @scratch)
      Command.capture("git", "checkout", "--quiet", "--detach", commit, directory: workspace)

      # Repository-provided agent configuration would change what this eval measures.
      reserved = %w[AGENTS.md CLAUDE.md opencode.json opencode.jsonc .opencode .agents .claude]
      reserved.each do |path|
        raise "Fixture contains agent configuration: #{path}" if File.exist?(File.join(workspace, path))
      end
      @skill_contents.each do |name, content|
        skill_directory = File.join(workspace, ".opencode", "skills", name)
        FileUtils.mkdir_p(skill_directory)
        File.write(File.join(skill_directory, "SKILL.md"), content)
      end
      File.write(File.join(workspace, "AGENTS.md"), @policy)
      workspace
    end

    def prepare_home(id)
      home = File.join(@scratch, id, "home")
      @harness.prepare_home(home)
      home
    end

    def run_trials(repository)
      trial_number = 0
      @repetitions.times do |repetition|
        commits.each do |commit|
          @targets.each_with_index do |target, target_index|
            trial_number += 1
            id = format("%04d", trial_number)
            result = run_trial(repository, id, commit, target)
            result.merge!("id" => id, "commit" => commit, "target" => target,
              "target_index" => target_index, "repetition" => repetition + 1)
            if result["session_id"] && @results.any? { |previous| previous["session_id"] == result["session_id"] }
              result["status"] = "invalid"
              result["errors"] << "Session ID reused across trials"
            end
            save_json("trials/#{id}/result.json", result)
            @results << result
            save_summary
            puts "#{id}/#{planned_trials} #{commit[0, 8]} #{target.fetch("model")} " \
              "#{target["variant"] || "(default variant)"}: #{result.fetch("status")}"
          end
        end
      end
    end

    def run_trial(repository, id, commit, target)
      artifacts = File.join(@output, "trials", id)
      Dir.mkdir(artifacts)
      prompt = @prompt_template.gsub("{{commit}}", commit)
      File.write(File.join(artifacts, "prompt.md"), prompt)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      workspace = prepare_workspace(repository, id, commit)
      home = prepare_home(id)
      execution = @harness.run(target: target, home: home, workspace: workspace,
        prompt: prompt, timeout: @timeout, artifacts: artifacts)
      trace = @harness.normalize_trace(File.join(artifacts, "trace.jsonl"))
      save_json("trials/#{id}/events.json", trace.fetch("events"))
      result = @scorer.score(trace, execution)
      File.write(File.join(artifacts, "draft.md"), result.fetch("final_response"))
      result.merge("execution" => execution,
        "duration_seconds" => Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
    ensure
      trial_directory = File.join(@scratch, id)
      FileUtils.remove_entry(trial_directory) if File.directory?(trial_directory)
    end

    def save_manifest
      snapshots = File.join(@output, "snapshots")
      Dir.mkdir(snapshots)
      @skill_contents.each { |name, content| File.write(File.join(snapshots, "#{name}.md"), content) }
      File.write(File.join(snapshots, "escalation-policy.md"), @policy)
      File.write(File.join(snapshots, "prompt-template.md"), @prompt_template)
      implementation_paths = [File.join(@directory, "run.rb"), *Dir[File.join(__dir__, "*.rb")]]
      implementation_hashes = implementation_paths.to_h do |path|
        [path.delete_prefix("#{@directory}/"), Digest::SHA256.file(path).hexdigest]
      end
      save_json("manifest.json", {
        "schema_version" => 1, "created_at" => Time.now.utc.iso8601,
        "suite" => @suite, "mode" => @options.fetch(:mode), "targets" => @targets,
        "repetitions" => @repetitions, "timeout_seconds" => @timeout,
        "planned_trials" => planned_trials, "prepare_only" => !!@options[:prepare_only],
        "ruby_version" => RUBY_VERSION, "repository_source" => @options[:repository] || @suite.fetch("repository"),
        "implementation_hashes" => implementation_hashes,
        "skill_hashes" => @skill_contents.transform_values { |content| Digest::SHA256.hexdigest(content) },
        "prompt_hash" => Digest::SHA256.hexdigest(@prompt_template),
        "policy_hash" => Digest::SHA256.hexdigest(@policy),
        "provider_config_hash" => Digest::SHA256.hexdigest(JSON.generate(@options.fetch(:provider_config))),
        "harness_config" => OpenCode::CONFIG
      })
    end

    def save_cases(repository)
      FileUtils.mkdir_p(File.join(@output, "cases"))
      commits.each do |commit|
        parent = Command.capture("git", "rev-parse", "#{commit}^1", directory: repository).strip
        message = Command.capture("git", "show", "--no-patch", "--format=%B", commit, directory: repository)
        patch = Command.capture("git", "diff", "--no-ext-diff", "--no-textconv", parent, commit, directory: repository)
        save_json("cases/#{commit}.json", {"commit" => commit, "parent" => parent,
          "message" => message, "patch_hash" => Digest::SHA256.hexdigest(patch)})
        File.write(File.join(@output, "cases", "#{commit}.patch"), patch)
      end
    end

    def save_summary(interrupted: false)
      groups = @targets.each_with_index.flat_map do |target, target_index|
        commits.map do |commit|
          results = @results.select { |result| result["target_index"] == target_index && result["commit"] == commit }
          TraceScorer.summarize(results).merge("target" => target, "commit" => commit)
        end
      end
      save_json("summary.json", {"attempted" => @results.size, "planned" => planned_trials,
        "interrupted" => interrupted, "groups" => groups})
    end

    def save_json(relative_path, data)
      File.write(File.join(@output, relative_path), "#{JSON.pretty_generate(data)}\n")
    end
  end
end
