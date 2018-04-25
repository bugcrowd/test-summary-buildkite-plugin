# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module Formatter
    def self.create(type: 'details', **options)
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
        "#{heading(input)}\n\n#{input_markdown(input)}"
      end

      def input_markdown(input)
        if show_first.negative? || show_first >= input.failures.count
          failures_markdown(input.failures)
        elsif show_first.zero?
          "<details><summary>Show failures</summary>\n#{failures_markdown(input.failures)}\n</details>"
        else
          failures_markdown(input.failures[0...show_first]) +
            "\n\n<details><summary>Show additional failures</summary>\n#{failures_markdown(input.failures[show_first..-1])}\n</details>"
        end
      end

      def failures_markdown(failures)
        failures.map { |failure| failure_markdown(failure) }.join("\n")
      end

      def heading(input)
        count = input.failures.count
        "##### #{input.label}: #{count} failure#{'s' unless count == 1}"
      end

      def show_first
        options[:show_first] || 20
      end
    end

    class Summary < Base
      def failure_markdown(failure)
        "    #{failure.summary}"
      end
    end

    class Details < Base
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
      summary: Formatter::Summary,
      details: Formatter::Details
    }.freeze
  end
end
