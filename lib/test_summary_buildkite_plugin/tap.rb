# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  # Parses most of the TAP protocol, assuming the inputs are sane.
  #
  # The specification is at https://testanything.org. This parses both
  # version 12 and version 13.
  #
  # Notable omissions:
  #
  #     * Test numbering and the planned number of tests are ignored.
  #     * "Bail out!" is ignored.
  #
  # Disclaimer:
  #
  #     This works about as well as you'd expect a hand-rolled parser made of
  #     regular expressions to work. Use at your own risk, pull requests welcome.
  #
  # TODO: Use a proper grammar and parser rather than regexes.
  class Tap
    class Suite
      attr_accessor :tests, :version

      def initialize
        self.version = 12
        self.tests = []
      end
    end

    Test = Struct.new(:passed, :description, :directive, :todo, :skipped, :diagnostic, :yaml,
                      keyword_init: true)

    class Parser
      PATTERNS = {
        plan: /^(?<start>\d+)\.\.(?<end>\d+)/,
        test:
          /^(?<not>not )?ok(?<number> \d+)?(?<description>[^#]*)(#\s*(?<directive>((?<todo>TODO)|(?<skip>SKIP))?.*))?/i,
        comment: /^#(?<comment>.*)$/,
        yaml_start: /^\s+---/,
        yaml_end: /^\s+\.\.\./,
        version: /^TAP version (?<version>\d+)/i
      }.freeze

      attr_reader :text
      attr_reader :suite

      def initialize(text)
        @text = text
        @suite = Suite.new
        @current_diagnostic = []
        @current_yaml = []
        @in_yaml = []
      end

      def parse # rubocop:disable Metrics/MethodLength
        text.split("\n").each do |line|
          type, match = type(line)
          case type
          when :test
            save_previous_blocks
            suite.tests.push(to_test(match))
          when :version
            suite.version = match['version'].to_i
          when :plan
            # we currently have no use for the 1..x info
            nil
          when :comment
            @current_diagnostic.push(match['comment'])
          when :yaml_start
            @in_yaml = true
          when :yaml_end
            @in_yaml = false
          else
            @current_yaml.push(line) if @in_yaml
            # as per the spec, we just ignore anything else we don't recognise
          end
        end
        save_previous_blocks
        suite
      end

      private

      def type(line)
        PATTERNS.each do |name, regex|
          match = regex.match(line)
          return name, match if match
        end
        [:unknown, nil]
      end

      def to_test(match)
        Test.new(
          passed: !match['not'],
          description: description(match),
          directive: match['directive'],
          todo: match['todo'],
          skipped: match['skip']
        )
      end

      def description(match)
        # There's a convention to put a ' - ' between the test number and the description
        # We strip that for better readability
        match['description'].strip.gsub(/^- /, '')
      end

      def save_previous_blocks
        last_test = suite.tests.last
        if last_test
          last_test.diagnostic = normalize_multiline(@current_diagnostic)
          last_test.yaml = normalize_multiline(@current_yaml)
        end
        @current_diagnostic = []
        @current_yaml = []
        @in_yaml = false
      end

      def normalize_multiline(lines)
        if lines.empty?
          nil
        else
          indent = lines.first.match(/(\s*)/)[1].length
          lines.map { |line| line[indent..-1] }.join("\n")
        end
      end
    end
  end
end
