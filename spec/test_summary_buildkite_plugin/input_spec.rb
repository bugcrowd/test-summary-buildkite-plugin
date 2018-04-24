# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Input do
  let(:label) { 'test' }
  let(:options) { { type: type, label: label, artifact_path: artifact_path }.merge(additional_options) }
  let(:additional_options) { {} }

  subject(:input) { TestSummaryBuildkitePlugin::Input.create(options) }

  describe 'oneline' do
    let(:type) { 'oneline' }
    let(:artifact_path) { 'rubocop.txt' }

    it { is_expected.to be_a(TestSummaryBuildkitePlugin::Input::OneLine) }

    it 'has all failures' do
      expect(input.failures.count).to eq(3)
    end

    it 'failures have no details' do
      expect(input.failures).to all(have_attributes(details: nil))
    end

    it 'failure summary includes whole line' do
      expect(input.failures.first.summary).to eq(
        '/Users/foo/test-summary-buildkite-plugin/lib/test_summary_buildkite_plugin/agent.rb:22:7: '\
        'C: Style/GuardClause: Use a guard clause instead of wrapping the code inside a conditional expression.'
      )
    end

    context 'cropping last entry' do
      let(:additional_options) { { crop: { start: 0, end: 1 } } }

      it 'has two failures' do
        expect(input.failures.count).to eq(2)
      end
    end

    context 'with blank lines' do
      let(:artifact_path) { 'eslint.txt' }

      it 'ignores blank lines' do
        expect(input.failures.count).to eq(2)
      end
    end
  end

  describe 'junit' do
    let(:type) { 'junit' }
    let(:artifact_path) { 'rspec-0.xml' }

    it { is_expected.to be_a(TestSummaryBuildkitePlugin::Input::JUnit) }

    it 'has all failures' do
      expect(input.failures.count).to eq(4)
    end

    it 'failures have details' do
      expect(input.failures.first.details).to eq('Failure/Error: it { expect(url).to be_allowed_url }
  expected http://example.com to be allowed by ["*.foo.example.com"] with resource_scheme http
./spec/lib/url_whitelist_spec.rb:96:in `block (4 levels) in &lt;top (required)&gt;\'')
    end

    it 'details escape html' do
      expect(input.failures.first.details).to include('&lt;')
    end

    it 'failures have file' do
      expect(input.failures.first.file).to eq('./spec/lib/url_whitelist_spec.rb')
    end

    it 'failures have name' do
      expect(input.failures.first.name).to eq('UrlWhitelist with domain wildcard should be allowed url')
    end

    it 'failures have no line' do
      expect(input.failures.first.line).to be_nil
    end

    it 'failures have no column' do
      expect(input.failures.first.column).to be_nil
    end
  end

  describe 'with glob path' do
    let(:type) { 'junit' }
    let(:artifact_path) { 'rspec*' }

    it 'has all failures' do
      expect(input.failures.count).to eq(5)
    end

    it 'sorts failures' do
      expect(input.failures.first.file).to eq('./spec/features/sign_in_out_spec.rb')
      expect(input.failures.last.file).to eq('./spec/lib/url_whitelist_spec.rb')
    end
  end

  describe 'tap' do
    let(:type) { 'tap' }
    let(:artifact_path) { 'example.tap' }

    it { is_expected.to be_a(TestSummaryBuildkitePlugin::Input::Tap) }

    it 'has all failures' do
      expect(input.failures.count).to eq(2)
    end

    it 'failures have details' do
      expect(input.failures.first.details).to eq('message: \'timeout\'
severity: fail')
    end

    it 'failures have name' do
      expect(input.failures.first.name).to eq('pinged quartz')
    end

    it 'failures have no file' do
      expect(input.failures.first.file).to be_nil
    end

    it 'failures have no line' do
      expect(input.failures.first.line).to be_nil
    end

    it 'failures have no column' do
      expect(input.failures.first.column).to be_nil
    end
  end
end
