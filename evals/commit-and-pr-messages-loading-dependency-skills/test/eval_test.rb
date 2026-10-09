require "minitest/autorun"
require "tempfile"
require_relative "../run"

class DependencySkillsEvalTest < Minitest::Test
  PARENT = DependencySkillsEval::TraceScorer::PARENT
  DEPENDENCY = DependencySkillsEval::TraceScorer::DEPENDENCY

  def setup
    @harness = DependencySkillsEval::OpenCode.new(executable: "opencode")
    @scorer = DependencySkillsEval::TraceScorer.new(
      PARENT => "parent body", DEPENDENCY => "first line\nsecond line"
    )
  end

  def tool(name, status: "completed", output: nil)
    output ||= %(<skill_content name="#{name}">body</skill_content>)
    {"type" => "tool_use", "sessionID" => "session",
     "part" => {"id" => name, "tool" => "skill",
                "state" => {"status" => status, "input" => {"name" => name}, "output" => output}}}
  end

  def response
    {"type" => "text", "sessionID" => "session", "part" => {"text" => "PR title\n\nPR body"}}
  end

  def finish(reason = "stop")
    {"type" => "step_finish", "sessionID" => "session", "part" => {"reason" => reason}}
  end

  def normalize(records)
    Tempfile.create("eval-trace") do |file|
      records.each { |record| file.puts(record.is_a?(String) ? record : JSON.generate(record)) }
      file.flush
      @harness.normalize_trace(file.path)
    end
  end

  def score(records, execution = {})
    trace = normalize([*records, response, finish])
    @scorer.score(trace, {"exit_code" => 0, "timed_out" => false}.merge(execution))
  end

  def test_completed_loads_pass_and_repeated_events_are_deduplicated
    result = score([tool(PARENT), tool(DEPENDENCY), tool(DEPENDENCY)])
    assert_equal "pass", result["status"]
    assert_equal 1, result.dig("evidence", DEPENDENCY, "loads").size
  end

  def test_failed_calls_and_mentions_do_not_count_as_loads
    [tool(DEPENDENCY, status: "error"), tool(DEPENDENCY, output: DEPENDENCY),
      tool(DEPENDENCY, output: "")].each do |record|
      assert_equal "dependency-missing", score([tool(PARENT), record])["status"]
    end
    assert_equal "dependency-missing", score([tool(PARENT),
      response.merge("part" => {"text" => "I loaded #{DEPENDENCY}"})])["status"]
  end

  def test_parent_discovery_and_dependency_failures_are_separate
    assert_equal "parent-missing", score([])["status"]
    assert_equal "parent-missing", score([tool(DEPENDENCY)])["status"]
    assert_equal "dependency-missing", score([tool(PARENT)])["status"]
  end

  def test_file_read_content_is_reported_separately
    read = {"type" => "tool_use", "sessionID" => "session", "part" => {"tool" => "read",
                                                                       "state" => {"status" => "completed", "input" => {},
                                                                                   "output" => "1: first line\n2: second line"}}}
    result = score([tool(PARENT), read])
    assert_equal "dependency-missing", result["status"]
    assert result.dig("evidence", DEPENDENCY, "content_delivered")
  end

  def test_harness_failures_are_invalid
    assert_equal "invalid", score([], "exit_code" => 1)["status"]
    assert_equal "invalid", score([], "timed_out" => true)["status"]
    error = {"type" => "error", "sessionID" => "session", "error" => {"message" => "rate limit"}}
    assert_equal "invalid", score([error])["status"]
  end

  def test_malformed_trace_records_are_invalid_without_crashing
    malformed = ["not JSON", "null", {"type" => "new-schema", "sessionID" => "session"},
      {"type" => "tool_use", "sessionID" => "session", "part" => nil},
      {"type" => "tool_use", "sessionID" => "session", "part" => {"state" => nil}},
      {"type" => "text", "sessionID" => "session", "part" => {"text" => 3}}]
    malformed.each do |record|
      result = score([record])
      assert_equal "invalid", result["status"]
      refute_empty result["errors"]
    end
  end

  def test_missing_and_abnormal_completion_are_invalid
    [[], [response], [response, finish("length")], [finish]].each do |records|
      result = @scorer.score(normalize(records), "exit_code" => 0)
      assert_equal "invalid", result["status"]
    end
  end

  def test_loads_after_final_response_do_not_count
    trace = normalize([response, tool(PARENT), tool(DEPENDENCY), finish])
    result = @scorer.score(trace, "exit_code" => 0)
    refute result["parent_loaded"]
    refute result["dependency_loaded"]
  end

  def test_multiple_sessions_are_invalid
    assert_equal "invalid", score([response.merge("sessionID" => "other")])["status"]
  end

  def test_summary_denominators_exclude_invalid_trials
    results = [score([tool(PARENT), tool(DEPENDENCY)]), score([tool(PARENT)]),
      score([]), score([], "exit_code" => 1)]
    summary = DependencySkillsEval::TraceScorer.summarize(results)
    assert_equal 4, summary["attempted"]
    assert_equal 1, summary["invalid"]
    assert_in_delta 1.0 / 3, summary.dig("dependency_loading", "fraction")
    assert_equal 0.5, summary.dig("dependency_given_parent", "fraction")
    assert_nil DependencySkillsEval::TraceScorer.rate(0, 0)["fraction"]
    assert_operator DependencySkillsEval::TraceScorer.rate(20, 20)["wilson_95"].first, :<, 0.85
  end

  def test_baseline_leaves_dependency_implicit
    directory = File.expand_path("..", __dir__)
    baseline = File.read(File.join(directory, "prompts", "baseline.md"))
    control = File.read(File.join(directory, "prompts", "control.md"))
    assert_includes baseline, PARENT
    refute_includes baseline, DEPENDENCY
    assert_includes control, DEPENDENCY
  end

  def test_target_validation_rejects_unknown_options_and_harnesses
    cli = DependencySkillsEval::CLI
    invalid_targets = [[], [{"harness" => "other", "model" => "provider/model"}],
      [{"harness" => "opencode", "model" => "luna"}],
      [{"harness" => "opencode", "model" => "provider/model", "variant" => ""}],
      [{"harness" => "opencode", "model" => "provider/model", "prompt" => "override"}]]
    invalid_targets.each { |targets| assert_raises(ArgumentError) { cli.validate_targets(targets) } }
    cli.validate_targets([{"harness" => "opencode", "model" => "provider/model", "variant" => "high"}])
  end

  def test_opencode_environment_isolated_and_inherited_overrides_removed
    previous = ENV["OPENCODE_CONFIG_CONTENT"]
    ENV["OPENCODE_CONFIG_CONTENT"] = '{"instructions":["unexpected.md"]}'
    environment = @harness.environment("/isolated/home", "/isolated/repository")
    assert_equal "/isolated/home", environment["HOME"]
    assert_equal "/isolated/home/config", environment["XDG_CONFIG_HOME"]
    assert_nil environment["OPENCODE_CONFIG_CONTENT"]
    assert_equal "/isolated/repository", environment["PWD"]
  ensure
    ENV["OPENCODE_CONFIG_CONTENT"] = previous
  end

  def test_command_failures_raise_and_timeout_kills_child
    command = DependencySkillsEval::Command
    assert_raises(RuntimeError) do
      command.capture(RbConfig.ruby, "-e", "exit 3", directory: Dir.pwd)
    end
    Dir.mktmpdir("eval-command-test-") do |directory|
      execution = command.record([RbConfig.ruby, "-e", "loop {}"], directory: directory,
        environment: {}, timeout: 0.1, trace_path: File.join(directory, "trace"),
        stderr_path: File.join(directory, "stderr"))
      assert execution["timed_out"]
      refute_equal 0, execution["exit_code"]
    end
  end
end
