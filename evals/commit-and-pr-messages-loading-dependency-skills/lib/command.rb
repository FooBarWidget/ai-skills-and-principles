require "open3"
require "timeout"

module DependencySkillsEval
  module Command
    def self.capture(*arguments, directory:, environment: {})
      stdout, stderr, status = Open3.capture3(environment, *arguments, chdir: directory)
      unless status.success?
        raise "#{arguments.first} #{arguments[1]} failed (#{status.exitstatus}): #{stderr.strip}"
      end

      stdout
    end

    def self.record(arguments, directory:, environment:, timeout:, trace_path:, stderr_path:)
      process_id = Process.spawn(environment, *arguments, chdir: directory,
        in: File::NULL, out: trace_path, err: stderr_path, pgroup: true)
      timed_out = false

      begin
        _, status = Timeout.timeout(timeout) { Process.wait2(process_id) }
      rescue Timeout::Error
        timed_out = true
        status = terminate(process_id)
      rescue Interrupt
        terminate(process_id)
        raise
      end

      {"exit_code" => status.exitstatus, "signal" => status.termsig, "timed_out" => timed_out}
    end

    def self.terminate(process_id)
      signal_group(process_id, "TERM")
      _, status = Timeout.timeout(2) { Process.wait2(process_id) }
      status
    rescue Timeout::Error
      signal_group(process_id, "KILL")
      Process.wait2(process_id).last
    end

    def self.signal_group(process_id, signal)
      Process.kill(signal, -process_id)
    rescue Errno::ESRCH
      # The process may have exited between the timeout and signal delivery.
    end
  end
end
