# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module Failure
    class Base
      def sort_key
        raise 'abstract method'
      end

      def oneline
        raise 'abstract method'
      end

      def verbose_markdown
        raise 'abstract method'
      end
    end

    class Oneline < Base
      attr_reader :line

      def initialize(line)
        @line = line
      end

      alias sort_key line

      def oneline
        "    #{line}"
      end

      def structure
        nil
      end
    end

    class Structured < Base
      attr_reader :failure

      def initialize(failure)
        @failure = failure
      end
    end
  end
end
