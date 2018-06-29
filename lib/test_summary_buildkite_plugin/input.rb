# frozen_string_literal: true

# We don't use nokogiri because we use an alpine-based docker image
# And adding the required dependencies triples the size of the image
require 'rexml/document'

module TestSummaryBuildkitePlugin
  module Input
    WORKDIR = 'tmp/test-summary'
    DEFAULT_JOB_ID_REGEX = /(?<job_id>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/

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
        @failures ||= begin
          f = files.map { |filename| filename_to_failures(filename) }.flatten
          f.each(&:strip_colors) if options[:strip_colors]
          f.sort_by(&:summary)
        end
      end

      protected

      def files
        @files ||= begin
          FileUtils.mkpath(WORKDIR)
          Agent.run('artifact', 'download', artifact_path, WORKDIR)
          Dir.glob("#{WORKDIR}/#{artifact_path}")
        end
      end

      def read(filename)
        File.read(filename).force_encoding(encoding)
      end

      def encoding
        @options[:encoding] || 'UTF-8'
      end

      def filename_to_failures(filename)
        file_contents_to_failures(read(filename)).each { |failure| failure.job_id = job_id(filename) }
      end

      def job_id(filename)
        filename.match(job_id_regex)&.named_captures&.fetch('job_id', nil)
      end

      def job_id_regex
        if @options[:job_id_regex]
          r = Regexp.new(@options[:job_id_regex])
          raise 'Job id regex must have a job_id named capture' unless r.names.include?('job_id')
          r
        else
          DEFAULT_JOB_ID_REGEX
        end
      end
    end

    class OneLine < Base
      def file_contents_to_failures(str)
        str.split("\n")[crop.start..crop.end]
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
      def file_contents_to_failures(str)
        xml = REXML::Document.new(str)
        xml.elements.enum_for(:each, '//testcase').each_with_object([]) do |testcase, failures|
          testcase.elements.each('failure | error') do |failure|
            failures << Failure::Structured.new(
              file: testcase.attributes['file']&.to_s,
              name: testcase.attributes['name']&.to_s,
              message: failure.attributes['message']&.to_s,
              details: details(failure)
            )
          end
        end
      end

      def details(failure)
        # gets all text elements that are direct children (includes CDATA), and use the unescaped values
        failure.texts.map(&:value).join('').strip
      end
    end

    class Tap < Base
      TEST_LINE = /^(?<not>not )?ok(?<test_number> \d+)?(?<description>[^#]*)(#(?<directive>.*))?/
      YAML_START = /^\s+---/
      YAML_END = /^\s+\.\.\./

      # TODO: Factor this out into its own parser class
      def file_contents_to_failures(tap) # rubocop:disable Metrics/MethodLength
        lines = tap.split("\n")
        raise 'Only TAP version 13 supported' unless lines.first.strip == 'TAP version 13'
        tests = []
        in_failure = false
        yaml_lines = nil
        lines.each do |line|
          if (matchdata = line.match(TEST_LINE))
            if matchdata['not']
              # start of a failing test
              in_failure = true
              tests << Failure::Structured.new(
                name: name(matchdata)
              )
            else
              # we're in a successful test, ignore subsequent lines until we hit a failure
              in_failure = false
            end
          elsif line.match?(YAML_START)
            yaml_lines = []
          elsif line.match?(YAML_END)
            tests.last.details = details(yaml_lines)
            yaml_lines = nil
          elsif in_failure && yaml_lines
            yaml_lines << line
          end
        end
        tests
      end

      def name(matchdata)
        # There's a convention to put a ' - ' between the test number and the description
        # We strip that for better readability
        matchdata['description'].strip.gsub(/^- /, '')
      end

      def details(yaml_lines)
        # strip indent
        indent = yaml_lines.first.match(/(\s*)/)[1].length
        yaml_lines.map { |line| line[indent..-1] }.join("\n")
      end
    end

    TYPES = {
      oneline: Input::OneLine,
      junit: Input::JUnit,
      tap: Input::Tap
    }.freeze
  end
end
