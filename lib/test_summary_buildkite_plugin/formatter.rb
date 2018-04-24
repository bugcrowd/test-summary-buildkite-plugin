# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module Formatter
    def self.create(type:, **options)
      type = type.to_sym
      raise StandardError, "Unknown formatter type: #{type}" unless TYPES.key?(type)
      TYPES[type].new(options)
    end

    class Base
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def markdown(input)
        return nil if input.failures.count.zero?
        "#{heading(input)}\n\n#{input.failures.map { |failure| failure_markdown(failure) }.join("\n")}"
      end

      def heading(input)
        count = input.failures.count
        "#{count} #{input.label} failure#{'s' unless count == 1}"
      end
    end

    class OneLine < Base
      def failure_markdown(failure)
        "    #{failure.summary}"
      end
    end

    class Verbose < Base
      # TODO
    end

    TYPES = {
      oneline: Formatter::OneLine,
      verbose: Formatter::Verbose
    }.freeze
  end
end
