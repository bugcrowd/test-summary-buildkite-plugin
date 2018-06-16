# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Truncater
    attr_reader :max_size, :inputs, :formatter_opts, :fail_on_error

    def initialize(max_size:, inputs:, formatter_opts: {}, fail_on_error: false)
      @max_size = max_size
      @inputs = inputs
      @formatter_opts = formatter_opts || {}
      @fail_on_error = fail_on_error
      @_input_markdown = {}
      @_formatter = {}
    end

    def markdown
      requested = markdown_with_truncation(nil)
      if requested.empty? || requested.bytesize < max_size
        # we can use it as-is, no need to truncate
        return requested
      end

      # See http://ruby-doc.org/core/Range.html#method-i-bsearch
      #
      # The block must return false for every value before the result
      # and true for the result and every value after
      best_truncate = (max_truncate..0).bsearch do |truncate|
        markdown_with_truncation(truncate).bytesize <= max_size
      end
      if best_truncate.nil?
        # If we end up here, we failed to find a valid truncation value
        # ASAICT this should never happen but if it does, something is very wrong
        # so ask the user to let us know
        bug_report_message
      end
      markdown_with_truncation(best_truncate)
    end

    private

    def formatter(truncate)
      @_formatter[truncate] ||= Formatter.create(formatter_opts.merge(truncate: truncate))
    end

    def input_markdown(input, truncate = nil)
      @_input_markdown[[input, truncate]] ||= formatter(truncate).markdown(input)
    rescue StandardError => e
      if fail_on_error
        raise
      else
        log_error(e)
        nil
      end
    end

    def markdown_with_truncation(truncate)
      inputs.map { |input| input_markdown(input, truncate) }.compact.join("\n\n")
    end

    def max_truncate
      @max_truncate ||= inputs.map(&:failures).map(&:count).max
    end

    def bug_report_message
      diagnostics = {
        max_size: max_size,
        formatter: formatter_opts,
        inputs: inputs.map do |input|
                  {
                    type: input.class,
                    failure_count: input.failures.count,
                    markdown_bytesize: input_markdown(input, nil).bytesize
                  }
                end
      }
      HamlRender.render('truncater_exception', diagnostics: diagnostics)
    end

    def log_error(err)
      puts "#{err.class}: #{err.message}\n\n#{err.backtrace.join("\n")}"
    end
  end
end
