# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Runner
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      markdown = inputs.map { |input| formatter.markdown(input) }.compact.join("\n\n")
      if markdown.empty?
        annotate('success', 'All tests passed :party:')
      else
        annotate('error', markdown)
      end
    end

    def annotate(style, markdown)
      Agent.run('annotate', '--context', context, '--style', style, stdin: markdown)
    end

    def formatter
      @formatter ||= Formatter.create(options[:formatter])
    end

    def inputs
      options[:inputs].map { |opts| Input.create(opts) }
    end

    def context
      options[:context] || 'test-summary'
    end

    def self.run
      plugins = JSON.parse(ENV.fetch('BUILDKITE_PLUGINS'), symbolize_names: true)
      options = plugins.find { |k, _v| k.to_s.include?('test-summary') }.last
      p options
      new(options).run
    end
  end
end
