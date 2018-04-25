# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Runner
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      markdown = inputs.map { |input| formatter.markdown(input) }.compact.join("\n\n")
      annotate(markdown) unless markdown.empty?
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

    def self.run
      plugins = JSON.parse(ENV.fetch('BUILDKITE_PLUGINS'), symbolize_names: true)
      # plugins is an array of hashes, keyed by <github-url>#<version>
      options = plugins.find { |k, _| k.to_s.include?('test-summary') }.values.first
      new(options).run
    end
  end
end
