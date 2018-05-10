# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Runner do
  let(:params) { { inputs: inputs } }
  let(:runner) { described_class.new(params) }

  subject(:run) { runner.run }

  context 'with no failures' do
    let(:inputs) do
      [
        label: 'rspec',
        type: 'junit',
        artifact_path: 'foo'
      ]
    end

    it 'does not call annotate' do
      run
      expect(agent_annotate_commands).to be_empty
    end
  end

  context 'with failures' do
    let(:inputs) do
      [
        label: 'rspec',
        type: 'junit',
        artifact_path: 'rspec*'
      ]
    end

    it 'calls annotate with correct args' do
      run
      expect(agent_annotate_commands.first).to include('annotate', '--context', 'test-summary', '--style', 'error')
    end

    context 'with custom style' do
      let(:params) { { inputs: inputs, style: 'warning' } }

      it 'calls annotate with correct args' do
        run
        expect(agent_annotate_commands.first).to include('annotate', '--context', 'test-summary', '--style', 'warning')
      end
    end

    context 'with custom context' do
      let(:params) { { inputs: inputs, context: 'ponies' } }

      it 'calls annotate with correct args' do
        run
        expect(agent_annotate_commands.first).to include('annotate', '--context', 'ponies', '--style', 'error')
      end
    end
  end

  context 'formatter raises exceptions' do
    let(:inputs) do
      [
        {
          label: 'rspec',
          type: 'junit',
          artifact_path: 'rspec*'
        },
        {
          label: 'eslint',
          type: 'oneline',
          artifact_path: 'eslint*'
        }
      ]
    end

    let(:formatter) { spy }

    before do
      allow(runner).to receive(:formatters).and_return([formatter])
      allow(formatter).to receive(:markdown).with(an_instance_of(TestSummaryBuildkitePlugin::Input::JUnit))
        .and_raise('life sucks')
      allow(formatter).to receive(:markdown).with(an_instance_of(TestSummaryBuildkitePlugin::Input::OneLine))
        .and_return('awesome markdown')
    end

    context 'without fail_on_error' do
      it 'continues' do
        run
        expect(agent_annotate_commands.first).to include(stdin: 'awesome markdown')
      end

      it 'logs the error' do
        expect { run }.to output(/life sucks/).to_stdout
      end
    end

    context 'with fail_on_error' do
      let(:params) { { inputs: inputs, fail_on_error: true } }

      it 'raises error' do
        expect { run }.to raise_error('life sucks')
      end
    end
  end

  context 'markdown is too large' do
    let(:inputs) do
      [
        label: 'rspec',
        type: 'junit',
        artifact_path: 'rspec*'
      ]
    end

    context 'for requested formatter' do
      before do
        stub_const('TestSummaryBuildkitePlugin::Runner::MAX_MARKDOWN_SIZE', 100)
      end

      it 'falls back to count_only formatter' do
        run
        expect(agent_annotate_commands.first).to include(stdin: '##### rspec: 6 failures')
      end
    end

    context 'for all formatters' do
      before do
        stub_const('TestSummaryBuildkitePlugin::Runner::MAX_MARKDOWN_SIZE', 1)
      end

      it 'raises an exception' do
        expect { run }.to raise_error(/Failed to generate annotation/)
      end
    end
  end
end
