# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Runner
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      markdown = inputs.map { |input| input_to_markdown(input) }.compact.join("\n\n")
      if markdown.empty?
        puts('No errors found! 🎉')
      else
        annotate(markdown)
      end
    end

    def input_to_markdown(input)
      formatter.markdown(input)
    rescue StandardError => e
      if fail_on_error
        raise
      else
        log_error(e)
        nil
      end
    end

    def annotate(markdown)
      Agent.run('annotate', '--context', context, '--style', style, stdin: markdown)
    end

    def formatter
      @formatter ||= Formatter.new(options[:formatter])
    end

    def inputs
      options[:inputs].map { |opts| Input.create(opts) }
    end

    def context
      options[:context] || 'test-summary'
    end

    def style
      options[:style] || 'error'
    end

    def fail_on_error
      options[:fail_on_error] || false
    end

    def log_error(err)
      puts "#{err.class}: #{err.message}\n\n#{err.backtrace.join("\n")}"
    end
  end
end
