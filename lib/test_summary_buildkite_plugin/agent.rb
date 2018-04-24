# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Agent
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :run, :stub, :stub=
    end

    attr_accessor :stub

    def run(*args, stdin: nil)
      log(args)
      cmd = command(args)
      IO.popen(cmd, 'w+') do |io|
        io.write(stdin) if stdin
        io.close_write
        puts io.read
      end
      if $CHILD_STATUS.exitstatus != 0
        raise "Command '#{cmd.join(' ')}' failed (exit status: #{$CHILD_STATUS.exitstatus})"
      end
    end

    def log(args)
      puts('$ buildkite-agent ' + args.join(' '))
    end

    def command(args)
      if stub
        %w[cat]
      else
        %w[buildkite-agent] + args
      end
    end
  end
end
