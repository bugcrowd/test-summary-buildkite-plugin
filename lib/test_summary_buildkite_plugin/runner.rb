# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Runner
    MAX_MARKDOWN_SIZE = 50_000

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      handled = formatters.any? do |formatter|
        puts("Using #{formatter.type} formatter")
        markdown = inputs.map { |input| input_to_markdown(formatter, input) }.compact.join("\n\n")

        if markdown.bytesize > MAX_MARKDOWN_SIZE
          puts("Markdown is too large (#{markdown.bytesize}B > #{MAX_MARKDOWN_SIZE}B)")
          false
        elsif markdown.empty?
          puts('No errors found! 🎉')
          true
        else
          annotate(markdown)
          true
        end
      end
      raise 'Failed to generate annotation' unless handled
    end

    def input_to_markdown(formatter, input)
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

    def formatters
      @formatters ||= begin
        # Try and do what people requested but fallback to simpler versions if we can't
        requested = Formatter.create(options[:formatter] || {})
        summary = Formatter.create((options[:formatter] || {}).merge(type: 'summary'))
        count_only = Formatter.create(type: :count_only)
        if requested.type == 'details'
          [requested, summary, count_only]
        else
          [requested, count_only]
        end
      end
    end

    def inputs
      @inputs ||= options[:inputs].map { |opts| Input.create(opts) }
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
