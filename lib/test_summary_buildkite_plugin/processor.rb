# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Processor
    include ErrorHandler

    attr_reader :formatter_options, :max_size, :output_path, :inputs, :fail_on_error

    def initialize(formatter_options:, max_size:, output_path:, inputs:, fail_on_error:)
      @formatter_options = formatter_options
      @max_size = max_size
      @output_path = output_path
      @inputs = inputs
      @fail_on_error = fail_on_error
      @_formatters = {}
    end

    def truncated_markdown
      @truncated_markdown ||= begin
        truncater = Truncater.new(
          max_size: max_size,
          max_truncate: inputs.map(&:failures).map(&:count).max
        ) do |truncate|
          inputs_markdown(truncate)
        end

        truncater.markdown
      rescue StandardError => e
        handle_error(e, diagnostics)
        HamlRender.render('truncater_exception', {})
      end
    end

    def inputs_markdown(truncate = nil)
      inputs.map { |input| input_markdown(input, truncate) }.compact.join("\n\n")
    end

    private

    def input_markdown(input, truncate)
      formatter(input).markdown(truncate)
    rescue StandardError => e
      handle_error(e)
    end

    def formatter(input)
      @_formatters[input] ||= Formatter.create(input: input, output_path: output_path, options: formatter_options)
    end

    def diagnostics
      {
        formatter: formatter_options,
        inputs: inputs.map do |input|
          {
            type: input.class,
            failure_count: input.failures.count,
            markdown_bytesize: input_markdown(input, nil)&.bytesize
          }
        end
      }
    end
  end
end
