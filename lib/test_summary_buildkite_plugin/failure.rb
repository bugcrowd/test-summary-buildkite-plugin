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
        if file && line && column
          "#{file}:#{line}:#{column}: "
        elsif file && line
          "#{file}:#{line}: "
        elsif file
          "#{file}: "
        end
      end
    end
  end
end
