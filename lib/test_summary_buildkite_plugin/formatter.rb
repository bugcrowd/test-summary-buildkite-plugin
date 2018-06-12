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
        if show_first.negative? || show_first >= input.failures.count
          failures_markdown(input.failures)
        elsif show_first.zero?
          details('Show failures', failures_markdown(input.failures))
        else
          failures_markdown(input.failures[0...show_first]) +
            details('Show additional failures', failures_markdown(input.failures[show_first..-1]))
        end
      end

      def failures_markdown(failures)
        render_template('failures', failures: failures)
      end

      def heading(input)
        count = input.failures.count
        "##### #{input.label}: #{count} failure#{'s' unless count == 1}"
      end

      def footer(input)
        job_ids = input.failures.map(&:job_id).uniq.reject(&:nil?)
        render_template('footer', job_ids: job_ids)
      end

      def show_first
        options[:show_first] || 20
      end

      def details(summary, contents)
        # This indents the close tag of nested <details> elements to work around a bug in redcarpet
        # See https://github.com/vmg/redcarpet/issues/652
        "<details>\n<summary>#{summary}</summary>\n#{contents.gsub(%r{^</details>}, '  </details>')}\n</details>"
      end

      def type
        options[:type] || 'details'
      end

      def render_template(name, params)
        filename = %W[templates/#{type}/#{name}.html.haml templates/#{name}.html.haml].find { |f| File.exist?(f) }
        if filename
          engine = Haml::Engine.new(File.read(filename), escape_html: true)
          engine.render(Object.new, params)
        end
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
