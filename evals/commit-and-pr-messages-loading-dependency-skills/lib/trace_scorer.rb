module DependencySkillsEval
  class TraceScorer
    PARENT = "commit-and-pr-messages"
    DEPENDENCY = "documentation-principles"
    SKILLS = [PARENT, DEPENDENCY].freeze

    def initialize(skill_bodies)
      @skill_bodies = skill_bodies
    end

    def score(trace, execution)
      events = trace.fetch("events")
      errors = trace.fetch("errors").dup
      errors << "Harness exited unsuccessfully" unless execution["exit_code"] == 0
      errors << "Trial timed out" if execution["timed_out"]
      sessions = events.map { |event| event["session_id"] }.uniq
      errors << "Expected exactly one session" unless sessions.size == 1
      events.select { |event| event["kind"] == "error" }.each do |event|
        errors << event["message"]
      end

      final_index = events.rindex { |event| event["kind"] == "text" && !event["text"].strip.empty? }
      errors << "No final response" unless final_index
      last_finish = events.reverse.find { |event| event["kind"] == "finish" }
      unless last_finish && %w[stop end_turn].include?(last_finish["reason"])
        errors << "No normal completion marker"
      end

      evidence = SKILLS.to_h { |name| [name, skill_evidence(events, name, final_index)] }
      parent_loaded = evidence[PARENT]["native_loaded"]
      dependency_loaded = evidence[DEPENDENCY]["native_loaded"]
      status = if !errors.empty?
        "invalid"
      elsif !parent_loaded
        "parent-missing"
      elsif dependency_loaded
        "pass"
      else
        "dependency-missing"
      end

      {"status" => status, "errors" => errors, "session_id" => sessions.first,
       "parent_loaded" => parent_loaded, "dependency_loaded" => dependency_loaded,
       "evidence" => evidence, "final_response" => final_index ? events[final_index]["text"] : ""}
    end

    def skill_evidence(events, name, final_index)
      loads = []
      events.each_with_index do |event, index|
        next unless event["kind"] == "tool" && event["status"] == "completed"

        output = event["output"]
        next unless output.is_a?(String)

        native = event["tool"] == "skill" && event.dig("input", "name") == name &&
          output.include?(%(<skill_content name="#{name}">))
        body = @skill_bodies.fetch(name)
        content_delivered = !body.empty? && output.gsub(/^\s*\d+: ?/, "").include?(body)
        next unless native || content_delivered

        loads << {"event_index" => index, "call_id" => event["call_id"], "tool" => event["tool"],
          "native" => native, "content_delivered" => content_delivered,
          "before_final_response" => final_index && index < final_index}
      end

      {"native_loaded" => loads.any? { |load| load["native"] && load["before_final_response"] },
       "content_delivered" => loads.any? { |load| load["content_delivered"] && load["before_final_response"] },
       "loads" => loads}
    end

    def self.summarize(results)
      valid = results.reject { |result| result["status"] == "invalid" }
      parent_loaded = valid.select { |result| result["parent_loaded"] }
      {
        "attempted" => results.size,
        "invalid" => results.size - valid.size,
        "parent_loading" => rate(parent_loaded.size, valid.size),
        "dependency_loading" => rate(valid.count { |result| result["dependency_loaded"] }, valid.size),
        "dependency_given_parent" => rate(parent_loaded.count { |result| result["dependency_loaded"] }, parent_loaded.size),
        "both_loading" => rate(valid.count { |result| result["status"] == "pass" }, valid.size),
        "dependency_content_delivered" => rate(valid.count { |result|
          result.fetch("evidence").fetch(DEPENDENCY).fetch("content_delivered")
        }, valid.size)
      }
    end

    # Wilson intervals remain meaningful for small samples, including 0/N and N/N.
    def self.rate(successes, total)
      result = {"successes" => successes, "total" => total, "fraction" => nil, "wilson_95" => nil}
      return result if total.zero?

      fraction = successes.fdiv(total)
      z_squared = 1.96**2
      denominator = 1 + z_squared / total
      center = (fraction + z_squared / (2 * total)) / denominator
      margin = 1.96 * Math.sqrt(fraction * (1 - fraction) / total + z_squared / (4 * total**2)) / denominator
      result.merge("fraction" => fraction,
        "wilson_95" => [[0, center - margin].max, [1, center + margin].min])
    end
  end
end
