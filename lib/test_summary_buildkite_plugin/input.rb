# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  WORKDIR = 'tmp/test-summary'

  module Input
    def self.create(type:, **options)
      type = type.to_sym
      raise StandardError, "Unknown file type: #{type}" unless TYPES.key?(type)
      TYPES[type].new(options)
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
          FileUtils.mkpath(WORKDIR)
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

    class OneLine < Base
      def failures_raw
        files.map { |file| read(file).split("\n")[crop.start..crop.end] }
             .flatten
             .reject(&:empty?)
             .map { |line| Failure::Unstructured.new(line) }
      end

      private

      def crop
        @crop ||= OpenStruct.new(
          start: options.dig(:crop, :start) || 0,
          end: -1 - (options.dig(:crop, :end) || 0)
        )
      end
    end

    class JUnit < Base
      def failures_raw
        files.map { |file| File.open(file) { |f| Nokogiri::XML(f, nil, encoding) } }
             .map { |xml| xml_to_failures(xml) }
             .flatten
      end

      private

      def xml_to_failures(xml)
        xml.css('testcase').each_with_object([]) do |testcase, failures|
          testcase.css('failure').each do |failure|
            failures << Failure::Structured.new(
              file: testcase['file'],
              name: testcase['name'],
              details: failure.content
            )
          end
        end
      end
    end

    class Tap < Base
      # TODO
    end

    TYPES = {
      oneline: Input::OneLine,
      junit: Input::JUnit,
      tap: Input::Tap
    }.freeze
  end
end
