# frozen_string_literal: true

require 'English'
require 'forwardable'
require 'singleton'

module TestSummaryBuildkitePlugin
  class Agent
    include Singleton

    class << self
      extend Forwardable
      def_delegators :instance, :run
    end

    attr_accessor :stub

    def run(*args, stdin: nil)
      log(args, stdin: stdin)
      cmd = %w[buildkite-agent] + args
      IO.popen(cmd, 'w+') do |io|
        io.write(stdin) if stdin
        io.close_write
        puts io.read
      end
      if $CHILD_STATUS.exitstatus != 0
        raise "Command '#{cmd.join(' ')}' failed (exit status: #{$CHILD_STATUS.exitstatus})"
      end
    end

    def log(args, stdin: nil)
      puts('$ buildkite-agent ' + args.join(' '))
      if stdin
        puts('# with stdin:')
        puts(stdin)
      end
    end
  end
end
