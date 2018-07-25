# frozen_string_literal: true

require 'haml'

module TestSummaryBuildkitePlugin
  class Formatter
    def self.create(**options)
      options[:type] ||= 'details'
      type = options[:type].to_sym
      raise "Unknown type: #{type}" unless TYPES.key?(type)
      TYPES[type].new(options)
    end

    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options || {}
      end

      def markdown(input)
        return nil if input.failures.count.zero?
        [heading(input), input_markdown(input), footer(input)].compact.join("\n\n")
      end

      def input_markdown(input)
        if show_first.negative? || show_first >= include_failures(input).count
          failures_markdown(include_failures(input))
        elsif show_first.zero?
          details('Show failures', failures_markdown(include_failures(input)))
        else
          failures_markdown(include_failures(input)[0...show_first]) +
            details('Show additional failures', failures_markdown(include_failures(input)[show_first..-1]))
        end
      end

      def failures_markdown(failures)
        render_template('failures', failures: failures)
      end

      def heading(input)
        count = input.failures.count
        show_count = include_failures(input).count
        s = "##### #{input.label}: #{count} failure#{'s' unless count == 1}"
        s += "\n\n_Including first #{show_count} failures_" if show_count < count
        s
      end

      def footer(input)
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

      def truncate
        options[:truncate]
      end

      def include_failures(input)
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

    class CountOnly < Base
      def markdown(input)
        return nil if input.failures.count.zero?
        heading(input)
      end
    end

    TYPES = {
      summary: Formatter::Summary,
      details: Formatter::Details,
      count_only: Formatter::CountOnly
    }.freeze
  end
end
