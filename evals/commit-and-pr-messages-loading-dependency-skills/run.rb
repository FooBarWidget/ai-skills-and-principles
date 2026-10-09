require "json"
require "optparse"
require "time"
require_relative "lib/runner"

module DependencySkillsEval
  class CLI
    def self.run(arguments)
      directory = __dir__
      data_home = ENV.fetch("XDG_DATA_HOME", File.join(Dir.home, ".local", "share"))
      auth_path = File.join(data_home, "opencode", "auth.json")
      options = {
        suite: File.join(directory, "suite.json"), mode: "baseline", executable: "opencode",
        skills_root: File.expand_path("../../skills", directory), provider_config: {},
        output: File.join(directory, "results", Time.now.utc.iso8601(6).tr(":", "-")),
        auth_path: File.file?(auth_path) ? auth_path : nil
      }
      parser = OptionParser.new do |parser|
        parser.banner = "Usage: ruby run.rb --model PROVIDER/MODEL [options]"
        parser.on("--model ID", "OpenCode provider/model ID") { |value| options[:model] = value }
        parser.on("--variant NAME", "Provider-specific reasoning effort") { |value| options[:variant] = value }
        parser.on("--matrix FILE", "JSON array of {harness, model, variant?}") { |value| options[:matrix] = value }
        parser.on("--repetitions N", Integer, "Trials per commit per target (default: 20)") { |value| options[:repetitions] = value }
        parser.on("--timeout-seconds N", Integer, "Per-trial timeout (default: 600)") { |value| options[:timeout] = value }
        parser.on("--mode NAME", %w[baseline control], "baseline or explicit-dependency control") { |value| options[:mode] = value }
        parser.on("--prepare-only", "Verify setup without model calls") { options[:prepare_only] = true }
        parser.on("--repo DIR", "Use a local clone instead of cloning GitHub") { |value| options[:repository] = File.expand_path(value) }
        parser.on("--out DIR", "New results directory; must not exist") { |value| options[:output] = File.expand_path(value) }
        parser.on("--suite FILE", "Alternate suite JSON") { |value| options[:suite] = File.expand_path(value) }
        parser.on("--skills-root DIR", "Alternate skills directory for comparisons") { |value| options[:skills_root] = File.expand_path(value) }
        parser.on("--provider-config FILE", "Provider-only OpenCode JSON; no instructions") { |value| options[:provider_config_path] = value }
        parser.on("--executable PATH", "OpenCode executable") { |value| options[:executable] = value }
        parser.on("-h", "--help", "Print usage") {
          puts parser
          return 0
        }
      end
      parser.parse!(arguments)
      raise ArgumentError, "Unexpected arguments: #{arguments.join(" ")}" unless arguments.empty?
      if options[:matrix] && (options[:model] || options[:variant])
        raise ArgumentError, "Use --matrix or --model/--variant, not both"
      end

      options[:targets] = if options[:matrix]
        JSON.parse(File.read(options[:matrix]))
      else
        [{"harness" => "opencode", "model" => options[:model], "variant" => options[:variant]}.compact]
      end
      validate_targets(options[:targets])
      if options[:provider_config_path]
        config = JSON.parse(File.read(options[:provider_config_path]))
        unless config.is_a?(Hash) && (config.keys - %w[provider enabled_providers]).empty?
          raise ArgumentError, "Provider config may contain only provider and enabled_providers"
        end
        options[:provider_config] = config
      end
      Runner.new(options).run
    end

    def self.validate_targets(targets)
      raise ArgumentError, "Matrix must be a nonempty array" unless targets.is_a?(Array) && !targets.empty?

      targets.each do |target|
        unless target.is_a?(Hash) && (target.keys - %w[harness model variant]).empty?
          raise ArgumentError, "Each target must contain harness, model, and optional variant"
        end
        raise ArgumentError, "Only OpenCode is currently supported" unless target["harness"] == "opencode"
        unless target["model"].is_a?(String) && target["model"].match?(/\A[^\s\/]+\/\S+\z/)
          raise ArgumentError, "Use a provider/model ID from opencode models"
        end
        if target.key?("variant") && (!target["variant"].is_a?(String) || target["variant"].strip.empty?)
          raise ArgumentError, "Variant must be a nonempty string"
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    exit DependencySkillsEval::CLI.run(ARGV)
  rescue => error
    warn "#{error.class}: #{error.message}"
    exit 1
  end
end
