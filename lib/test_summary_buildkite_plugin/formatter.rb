# frozen_string_literal: true

require 'haml'

module TestSummaryBuildkitePlugin
  class Formatter
    attr_reader :options

    def initialize(options = {})
      @options = options || {}
      raise "Unknown type: #{type}" unless %w[summary details].include?(type)
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
      # The empty paragraph puts padding between the details and the following element
      "<details><summary>#{summary}</summary>\n#{contents}\n</details><p></p>"
    end

    def type
      options[:type] || 'details'
    end

    def render_template(name, params)
      filename = %W[templates/#{type}/#{name}.html.haml templates/#{name}.html.haml].find { |f| File.exist?(f) }
      if filename
        engine = Haml::Engine.new(File.read(filename))
        engine.render(Object.new, params)
      end
    end
  end
end
