# frozen_string_literal: true

require 'haml'

module TestSummaryBuildkitePlugin
  class Formatter
    def self.create(input:, output_path:, options:)
      options[:type] ||= 'details'
      type = options[:type].to_sym
      raise "Unknown type: #{type}" unless TYPES.key?(type)
      TYPES[type].new(input: input, output_path: output_path, options: options)
    end

    class Base
      attr_reader :input, :output_path, :options

      def initialize(input:, output_path:, options:)
        @input = input
        @output_path = output_path
        @options = options || {}
      end

      def markdown(truncate)
        return nil if input.failures.count.zero?
        [heading(truncate), input_markdown(truncate), footer].compact.join("\n\n")
      end

      protected

      def input_markdown(truncate)
        failures = include_failures(truncate)

        if show_first.negative? || show_first >= failures.count
          failures_markdown(failures, truncate)
        elsif show_first.zero?
          details('Show failures', failures_markdown(failures, truncate))
        else
          failures_markdown(failures[0...show_first], false) +
            details('Show additional failures', failures_markdown(failures[show_first..-1], truncate))
        end
      end

      def failures_markdown(failures, truncate)
        render_template('failures', failures: failures, output_path: truncate ? output_path : nil)
      end

      def heading(truncate)
        count = input.failures.count
        show_count = include_failures(truncate).count
        s = "##### #{input.label}: #{count} failure#{'s' unless count == 1}"
        s += "\n\n_Including first #{show_count} failures_" if show_count < count
        s
      end

      def footer
        job_ids = input.failures.map(&:job_id).uniq.reject(&:nil?)
        render_template('footer', job_ids: job_ids)
      end

      def show_first
        options[:show_first] || 20
      end

      def details(summary, contents)
        "<details>\n<summary>#{summary}</summary>\n#{contents}\n</details>"
      end

      def type
        options[:type] || 'details'
      end

      def include_failures(truncate)
        if truncate
          input.failures[0...truncate]
        else
          input.failures
        end
      end

      def render_template(name, params)
        # In CommonMark (used by buildkite), most html block elements are terminated by a blank line
        # So we need to ensure we don't have any of those in the middle of our html
        #
        # See https://spec.commonmark.org/0.28/#html-blocks
        HamlRender.render(name, params, folder: type)&.gsub(/\n\n+/, "\n&nbsp;\n")
      end
    end

    class Summary < Base; end

    class Details < Base; end

    TYPES = {
      summary: Formatter::Summary,
      details: Formatter::Details
    }.freeze
  end
end
