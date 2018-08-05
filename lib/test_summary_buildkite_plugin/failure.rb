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
      attr_accessor :summary, :message, :details

      def initialize(summary:, message: nil, details: nil)
        @summary = summary
        @message = message
        @details = details
      end
    end
  end
end
