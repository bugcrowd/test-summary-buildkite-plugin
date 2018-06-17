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
      puts "Markdown is too large (#{requested.bytesize} B > #{max_size} B), truncating"

      # See http://ruby-doc.org/core/Range.html#method-i-bsearch
      #
      # The block must return false for every value before the result
      # and true for the result and every value after
      best_truncate = (0..max_truncate).to_a.reverse.bsearch do |truncate|
        puts "Test truncating to #{truncate}: bytesize=#{markdown_with_truncation(truncate).bytesize}"
        markdown_with_truncation(truncate).bytesize <= max_size
      end
      if best_truncate.nil?
        # If we end up here, we failed to find a valid truncation value
        # ASAICT this should never happen but if it does, something is very wrong
        # so ask the user to let us know
        return bug_report_message
      end
      puts "Optimal truncation: #{best_truncate}"
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
      puts
      puts 'Optimization failed 😱'
      puts 'Please report this to https://github.com/bugcrowd/test-summary-buildkite-plugin/issues'
      puts 'with the test log above and the details below.'
      puts JSON.pretty_generate(diagnostics)
      HamlRender.render('truncater_exception', {})
    end

    def diagnostics
      {
        max_size: max_size,
        formatter: formatter_opts,
        inputs: inputs.map do |input|
          {
            type: input.class,
            failure_count: input.failures.count,
            markdown_bytesize: input_markdown(input, nil)&.bytesize
          }
        end
      }
    end

    def log_error(err)
      puts "#{err.class}: #{err.message}\n\n#{err.backtrace.join("\n")}"
    end
  end
end
