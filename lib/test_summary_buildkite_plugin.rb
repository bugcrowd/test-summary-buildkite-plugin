# frozen_string_literal: true

require 'English'
require 'singleton'
require 'json'

require 'test_summary_buildkite_plugin/agent'
require 'test_summary_buildkite_plugin/failure'
require 'test_summary_buildkite_plugin/formatter'
require 'test_summary_buildkite_plugin/input'
require 'test_summary_buildkite_plugin/runner'
require 'test_summary_buildkite_plugin/version'

module TestSummaryBuildkitePlugin
  WORKDIR = 'tmp/test-summary'
  PARSERS = {
    oneline: Input::OneLine,
    junit: Input::JUnit,
    tap: Input::Tap
  }.freeze
  FORMATTERS = {
    oneline: Formatter::OneLine,
    verbose: Formatter::Verbose
  }.freeze
end
