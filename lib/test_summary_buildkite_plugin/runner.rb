# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Runner
    MAX_MARKDOWN_SIZE = 6_000

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      markdown = Truncater.new(
        max_size: MAX_MARKDOWN_SIZE,
        inputs: inputs,
        formatter_opts: options[:formatter],
        fail_on_error: fail_on_error
      ).markdown
      if markdown.nil? || markdown.empty?
        puts('No errors found! 🎉')
      else
        annotate(markdown)
      end
    end

    def annotate(markdown)
      Agent.run('annotate', '--context', context, '--style', style, stdin: markdown)
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
  end
end
