# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module Input
    def self.create(type:, **options)
      type = type.to_sym
      raise StandardError, "Unknown file type: #{type}" unless PARSERS.key?(type)
      PARSERS[type].new(options)
    end

    class Base
      attr_reader :label, :artifact_path, :options

      def initialize(label:, artifact_path:, **options)
        @label = label
        @artifact_path = artifact_path
        @options = options
      end

      def failures
        @failures ||= failures_raw.sort_by(&:sort_key)
      end

      protected

      def files
        @files ||= begin
          Agent.run('artifact', 'download', artifact_path, WORKDIR)
          Dir.glob("#{WORKDIR}/#{artifact_path}")
        end
      end

      def failures_raw
        raise 'abstract method'
      end

      def read(filename)
        File.read(filename).force_encoding(encoding)
      end

      def encoding
        @options[:encoding] || 'UTF-8'
      end
    end

    class JUnit < Base
      # TODO
    end

    class OneLine < Base
      def failures_raw
        files.map { |file| read(file).split("\n")[crop.start...-crop.end] }
             .flatten
             .reject(&:empty?)
             .map { |line| Failure::Oneline.new(line) }
      end

      private

      def crop
        @crop ||= OpenStruct.new(
          start: options.dig(:crop, :start) || 0,
          end: options.dig(:crop, :end) || 0
        )
      end
    end

    class Tap < Base
      # TODO
    end
  end
end
