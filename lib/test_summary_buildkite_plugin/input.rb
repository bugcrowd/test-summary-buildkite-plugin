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
          Dir.glob("#{WORKDIR}/*.xml")
          # /tmp/dir/logs\nunit\asdasd.log
        rescue Agent::CommandFailed => err
          if fail_on_error
            raise
          else
            Utils.log_error(err)
            []
          end
        end
      end

      def read(filename)
        File.read(filename).force_encoding(encoding)
      end

      def encoding
        @options[:encoding] || 'UTF-8'
      end

      def fail_on_error
        @options[:fail_on_error] || false
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
              summary: summary(failure),
              message: message(failure),
              details: details(failure)
            )
          end
        end
      end

      def summary(failure)
        data = attributes(failure)
        if summary_format
          summary_format % data
        else
          name = data[:'testcase.name']
          file = data[:'testcase.file']
          class_name = data[:'testcase.classname']
          location = if !file.nil? && !file.empty?
                       "#{file}: "
                     elsif !class_name.nil? && !class_name.empty? && class_name != name
                       "#{class_name}: "
                     end
          "#{location}#{name}"
        end
      end

      def attributes(failure)
        # If elements are used in the format string but don't exist in the map, pretend they're blank
        acc = Hash.new('')
        elem = failure
        until elem.parent.nil?
          elem.attributes.each do |attr_name, attr_value|
            acc["#{elem.name}.#{attr_name}".to_sym] = attr_value
          end
          elem = elem.parent
        end
        acc.merge(detail_attributes(failure))
      end

      def detail_attributes(failure)
        matches = details_regex&.match(details(failure))&.named_captures || {}
        # need to symbolize keys
        matches.each_with_object({}) do |(key, value), acc|
          acc[key.to_sym] = value
        end
      end

      def details(failure)
        if options.fetch(:details, true)
          # gets all text elements that are direct children (includes CDATA), and use the unescaped values
          failure.texts.map(&:value).join('').strip
        end
      end

      def message(failure)
        failure.attributes['message']&.to_s if options.fetch(:message, true)
      end

      def summary_format
        @summary_format ||= options.dig(:summary, :format)
      end

      def details_regex
        @details_regex ||= begin
          regex_str = options.dig(:summary, :details_regex)
          Regexp.new(regex_str) if regex_str
        end
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
                summary: summary(matchdata)
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

      def summary(matchdata)
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

    class Checkstyle < Base
      def file_contents_to_failures(str)
        xml = REXML::Document.new(str)
        xml.elements.enum_for(:each, '//file').flat_map do |file|
          filename = file.attribute('name').value

          file.elements.map do |error|
            Failure::Structured.new(
              summary: summary(filename, error),
              details: error.attribute('source').value
            )
          end
        end
      end

      def summary(filename, error)
        severity = error.attribute('severity')&.value
        line = error.attribute('line')&.value
        column = error.attribute('column')&.value
        location = [filename, line, column].compact.join(':')
        message = error.attribute('message')&.value

        "[#{severity}] #{location}: #{message}"
      end
    end

    class NUnit < Base
      def file_contents_to_failures(str)
        failures = []
        xml = REXML::Document.new(str)
        testcases(xml).each do |testcase|
          testcase.elements.each('failure') do |failure|
            failures << Failure::Structured.new(
              summary: summary(failure),
              message: message(failure),
              details: details(failure)
            )
          end
        end

        failures
      end

      def summary(failure)
        data = attributes(failure)
        name = data[:'test-case.fullname']
        "#{name}"
      end

      def message(failure)
        message = failure.elements['message'].text
        "#{message}"
      end

      def details(failure)
        message = failure.elements['message'].text
        stack_trace = failure.elements['stack-trace']
        detail = if !stack_trace.nil? then "#{stack_trace.text}" else "" end
        "#{message}\n#{detail}"
      end

      def attributes(failure)
        # If elements are used in the format string but don't exist in the map, pretend they're blank
        acc = Hash.new('')
        elem = failure
        until elem.parent.nil?
          elem.attributes.each do |attr_name, attr_value|
            acc["#{elem.name}.#{attr_name}".to_sym] = attr_value
          end
          elem = elem.parent
        end
        acc
      end

      def testcases(doc)
        test_suites = []
        test_cases = []

        doc.elements['test-run'].elements.each('test-suite') do |testsuite|
          test_suites << testsuite
        end

        while test_suites.length != 0 do
          testsuite = test_suites.shift()
          testsuite.elements.each('test-suite') do |child_testsuite| 
            test_suites << child_testsuite
          end
          testsuite.elements.each('test-case') do |testcase| 
            test_cases << testcase
          end
        end
        test_cases
      end
    end

    TYPES = {
      oneline: Input::OneLine,
      junit: Input::JUnit,
      tap: Input::Tap,
      checkstyle: Input::Checkstyle,
      nunit: Input::NUnit
    }.freeze
  end
end
