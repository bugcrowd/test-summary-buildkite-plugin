# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module Failure
    # All failure classes should have #summary and #details methods
    class Base
      attr_accessor :job_id

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

      def message; end
    end

    class Structured < Base
      attr_accessor :file, :name, :message, :details

      def initialize(name:, file: nil, message: nil, details: nil)
        @file = file
        @name = name
        @message = message
        @details = details
      end

      def summary
        "#{location}#{name}"
      end

      private

      def location
        "#{file}: " unless file.nil? || file.empty?
      end
    end
  end
end
