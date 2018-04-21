# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Agent
    include Singleton

    class << self
      extend Forwardable
      def_delegator :instance, :run
    end

    attr_accessor :stub

    def run(*args, stdin: nil)
      cmd = command(args)
      puts('$ ' + cmd.join(' '))
      IO.popen(cmd, 'w+') do |io|
        io.write(stdin) if stdin
        io.close_write
        puts io.read
      end
      if $CHILD_STATUS.exitstatus != 0
        raise "Command '#{cmd.join(' ')}' failed (exit status: #{$CHILD_STATUS.exitstatus})"
      end
    end

    def command(args)
      if stub
        %w[buildkite-agent] + args
      else
        %w[echo buildkite-agent] + args
      end
    end
  end
end
