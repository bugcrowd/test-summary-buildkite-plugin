# frozen_string_literal: true

require 'haml'

module TestSummaryBuildkitePlugin
  class Formatter
    attr_reader :options

    def initialize(options)
      @options = options
      raise "Unknown type: #{options[:type]}" unless %w[summary details].include?(options[:type])
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
      engine = Haml::Engine.new(File.read("templates/#{options[:type]}/failures.html.haml"))
      engine.render(Object.new, failures: failures)
    end

    def heading(input)
      count = input.failures.count
      "##### #{input.label}: #{count} failure#{'s' unless count == 1}"
    end

    def show_first
      options[:show_first] || 20
    end
  end
end
