# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module Formatter
    def self.create(type:, **options)
      type = type.to_sym
      raise StandardError, "Unknown formatter type: #{type}" unless TYPES.key?(type)
      TYPES[type].new(options)
    end

    class Base
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def markdown(input)
        return nil if input.failures.count.zero?
        "#{heading(input)}\n\n#{failures_markdown(input)}"
      end

      def failures_markdown(input)
        input.failures.map { |failure| failure_markdown(failure) }.join("\n")
      end

      def heading(input)
        count = input.failures.count
        "##### #{input.label}: #{count} failure#{'s' unless count == 1}"
      end
    end

    class OneLine < Base
      def failure_markdown(failure)
        "    #{failure.summary}"
      end
    end

    class Verbose < Base
      def failure_markdown(failure)
        if failure.details
          <<~END_MARKDOWN
            <li>
              <details>
                <summary><code>#{failure.summary}</code></summary>
                <code><pre>#{failure.details}</pre></code>
              </details>
            </li>
          END_MARKDOWN
        else
          "<li><code>#{failure.summary}</code></li>"
        end
      end

      def failures_markdown(input)
        "<ul>#{super(input)}</ul>"
      end
    end

    TYPES = {
      oneline: Formatter::OneLine,
      verbose: Formatter::Verbose
    }.freeze
  end
end
