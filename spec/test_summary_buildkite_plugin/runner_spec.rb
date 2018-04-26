# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Runner do
  let(:params) { { inputs: inputs } }

  subject(:run) { described_class.new(params).run }

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
end
