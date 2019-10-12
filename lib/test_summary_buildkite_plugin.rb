# frozen_string_literal: true

require 'json'

require 'test_summary_buildkite_plugin/agent'
require 'test_summary_buildkite_plugin/failure'
require 'test_summary_buildkite_plugin/formatter'
require 'test_summary_buildkite_plugin/haml_render'
require 'test_summary_buildkite_plugin/input'
require 'test_summary_buildkite_plugin/runner'
require 'test_summary_buildkite_plugin/tap'
require 'test_summary_buildkite_plugin/truncater'
require 'test_summary_buildkite_plugin/utils'
require 'test_summary_buildkite_plugin/version'

module TestSummaryBuildkitePlugin
  def self.run
    plugins = JSON.parse(ENV.fetch('BUILDKITE_PLUGINS'), symbolize_names: true)
    # plugins is an array of hashes, keyed by <github-url>#<version>
    options = plugins.find { |k, _| k.to_s.include?('test-summary') }.values.first
    Runner.new(options).run
  end
end
