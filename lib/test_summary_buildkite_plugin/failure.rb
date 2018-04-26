# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module Failure
    # All failure classes should have #summary and #details methods
    class Base
      def summary
        raise 'abstract method'
      end

      def details
        raise 'abstract method'
      end

      def strip_colors
        instance_variables.each do |var|
          value = instance_variable_get(var)
          instance_variable_set(var, value.gsub(/\\e\[[\d;]+m/, '')) if value.is_a?(String)
        end
      end
    end

    class Unstructured < Base
      attr_reader :summary

      def initialize(summary)
        @summary = summary
      end

      def details; end
    end

    class Structured < Base
      attr_accessor :file, :line, :column, :name, :details

      def initialize(name:, file: nil, line: nil, column: nil, details: nil)
        @file = file
        @line = line
        @column = column
        @name = name
        @details = details
      end

      def summary
        "#{location}#{name}"
      end

      private

      def location
        reference = [file, line, column].compact.join(':')
        "#{reference}: " unless reference.empty?
      end
    end
  end
end
