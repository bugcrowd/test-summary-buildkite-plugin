# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Main
    MAX_MARKDOWN_SIZE = 100_000
    OUTPUT_PATH = 'test-summary.html'

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      processor = Processor.new(
        formatter_options: formatter,
        max_size: MAX_MARKDOWN_SIZE,
        output_path: OUTPUT_PATH,
        inputs: inputs,
        fail_on_error: fail_on_error
      )

      if processor.truncated_markdown.nil? || processor.truncated_markdown.empty?
        puts('No errors found! 🎉')
      else
        upload_artifact(processor.inputs_markdown)
        annotate(processor.truncated_markdown)
      end
    end

    private

    def upload_artifact(markdown)
      File.write(OUTPUT_PATH, Utils.standalone_markdown(markdown))
      Agent.run('artifact', 'upload', OUTPUT_PATH)
    end

    def annotate(markdown)
      Agent.run('annotate', '--context', context, '--style', style, stdin: markdown)
    end

    def formatter
      options[:formatter] || {}
    end

    def inputs
      @inputs ||= options[:inputs].map { |opts| Input.create(opts.merge(fail_on_error: fail_on_error)) }
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
