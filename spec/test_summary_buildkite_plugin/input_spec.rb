# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Input do
  let(:label) { 'test' }
  let(:options) { { type: type, label: label, artifact_path: artifact_path }.merge(additional_options) }
  let(:additional_options) { {} }

  subject(:input) { described_class.create(options) }

  describe 'oneline' do
    let(:type) { 'oneline' }
    let(:artifact_path) { 'rubocop.txt' }

    it { is_expected.to be_a(TestSummaryBuildkitePlugin::Input::OneLine) }

    it 'downloads artifacts' do
      input.failures
      expect(agent_commands).to include(%w[artifact download rubocop.txt spec/sample_artifacts])
    end

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
      let(:artifact_path) { 'eslint-00112233-0011-0011-0011-001122334455.txt' }

      it 'ignores blank lines' do
        expect(input.failures.count).to eq(3)
      end
    end
  end

  describe 'junit' do
    let(:type) { 'junit' }
    let(:artifact_path) { 'rspec-aabbccdd-0011-0011-0011-001122334455.xml' }

    it { is_expected.to be_a(TestSummaryBuildkitePlugin::Input::JUnit) }

    it 'has all failures' do
      expect(input.failures.count).to eq(4)
    end

    it 'failures have details' do
      expect(input.failures.first.details).to start_with('Failure/Error: ')
    end

    it 'failures have file' do
      expect(input.failures.first.summary).to include('./spec/lib/url_whitelist_spec.rb')
    end

    it 'failures have name' do
      expect(input.failures.first.summary).to include('UrlWhitelist with domain wildcard should be allowed url')
    end

    context 'without strip_colors' do
      it 'keeps color sequences' do
        expect(input.failures.first.details).to include('\e[0m')
      end
    end

    context 'with strip_colors' do
      let(:additional_options) { { strip_colors: true } }

      it 'removes color sequences' do
        expect(input.failures.first.details).not_to include('\e[0m')
      end
    end

    context 'with error and skip elements and testsuites' do
      let(:artifact_path) { 'xunit.xml' }

      it 'includes the error' do
        expect(input.failures.map(&:summary)).to include(/shows default results when defaultCategory is set/)
      end

      it 'ignores skipped test' do
        expect(input.failures.count).to eq(3)
      end

      it 'when message is not present has a nil message' do
        expect(input.failures).to include(have_attributes(message: nil))
      end
    end

    context 'with summary_format' do
      let(:artifact_path) { 'xunit.xml' }
      let(:additional_options) do
        { summary: { format: '%{testsuites.name}: %{testsuite.name}: %{testcase.classname} (%{error.message})' } }
      end

      it 'sets summary based on format' do
        expect(input.failures.map(&:summary)).to(
          include(
            'jest tests: xunit: Chrome 66.0 (has results after focusing)',
            'jest tests: Login: Login should load without error ()'
          )
        )
      end

      context 'with details regex' do
        let(:artifact_path) { 'rspec-01234567-0011-0011-0011-001122334455.xml' }
        let(:additional_options) do
          { summary: {
            format: '%{location}: %{testcase.name}',
            details_regex: '(?<location>\S+:\d+)'
          } }
        end

        it 'sets summary based on format' do
          expect(input.failures.map(&:summary)).to(
            include(
              './spec/features/sign_in_out_spec.rb:27: signing in and out sign_in reset password'
            )
          )
        end
      end
    end
  end

  describe 'androidLint' do
    let(:type) { 'androidLint' }
    let(:artifact_path) { 'android-lint-results.xml' }

    it { is_expected.to be_a(TestSummaryBuildkitePlugin::Input::AndroidLint) }

    it 'has all failures' do
      expect(input.failures.count).to eq(1)
    end

    it 'has summary' do
      summary = input.failures.first.summary

      expect(summary).to include '[Correctness: GradleDependency]'
      expect(summary).to include 'Warning:'
      expect(summary).to include 'Obsolete Gradle Dependency'
      expect(summary).to include '/Users/timnew/Workspace/jora/sol-sdk-android/demo/build.gradle:32'
    end

    it 'has message' do
      expect(input.failures.first.message).to eq 'A newer version of com.android.support.constraint:constraint-layout than 1.1.2 is available: 1.1.3'
    end

    it 'has summary' do
      expect(input.failures.first.details).to eq 'This detector looks for usages of libraries where the version you are using is not the current stable release. Using older versions is fine, and there are cases where you deliberately want to stick with an older version. However, you may simply not be aware that a more recent version is available, and that is what this lint check helps find.'
    end
  end

  describe 'with glob path' do
    let(:type) { 'junit' }
    let(:artifact_path) { 'rspec*' }

    it 'has all failures' do
      expect(input.failures.count).to eq(6)
    end

    it 'sorts failures' do
      expect(input.failures.first.summary).to include('./spec/features/sign_in_out_spec.rb')
      expect(input.failures.last.summary).to include('./spec/lib/url_whitelist_spec.rb')
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

    it 'failures have summary' do
      expect(input.failures.first.summary).to eq('pinged quartz')
    end
  end

  describe 'setting ascii encoding' do
    let(:type) { 'oneline' }
    let(:artifact_path) { 'eslint-00112233-0011-0011-0011-001122334455.txt' }
    let(:additional_options) { { encoding: 'ascii' } }

    it 'tries to parse as ascii' do
      expect { input.failures }.to raise_error('invalid byte sequence in US-ASCII')
    end
  end

  describe 'job_id' do
    let(:type) { 'oneline' }

    context 'with uuid in path' do
      let(:artifact_path) { 'eslint-00112233-0011-0011-0011-001122334455.txt' }

      it 'failures have job_id' do
        expect(input.failures.first.job_id).to eq('00112233-0011-0011-0011-001122334455')
      end
    end

    context 'without uuid in path' do
      let(:artifact_path) { 'rubocop.txt' }

      it 'failures have no job_id' do
        expect(input.failures.first.job_id).to be_nil
      end
    end

    context 'with custom job_id_regex' do
      let(:additional_options) { { job_id_regex: '(?<job_id>eslint)' } }
      let(:artifact_path) { 'eslint-00112233-0011-0011-0011-001122334455.txt' }

      it 'uses the regex' do
        expect(input.failures.first.job_id).to eq('eslint')
      end
    end

    context 'with bad custom job_id_regex' do
      let(:additional_options) { { job_id_regex: '(eslint)' } }
      let(:artifact_path) { 'eslint-00112233-0011-0011-0011-001122334455.txt' }

      it 'gives helpful error' do
        expect { input.failures }.to raise_error(/must have a job_id named capture/)
      end
    end
  end
end
