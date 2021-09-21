# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Processor do
  let(:processor) do
    described_class.new(
      formatter_options: {},
      max_size: 50_000,
      output_path: 'foo',
      inputs: inputs,
      fail_on_error: fail_on_error
    )
  end

  context 'formatter raises exceptions' do
    let(:formatter1) { spy }
    let(:formatter2) { spy }

    let(:input1) { double(TestSummaryBuildkitePlugin::Input::Base) }
    let(:input2) { double(TestSummaryBuildkitePlugin::Input::Base) }
    let(:inputs) { [input1, input2] }

    before do
      allow(processor).to receive(:formatter).with(input1).and_return(formatter1)
      allow(formatter1).to receive(:markdown).with(nil).and_raise('life sucks')
      allow(processor).to receive(:formatter).with(input2).and_return(formatter2)
      allow(formatter2).to receive(:markdown).with(nil).and_return('awesome markdown')
      allow(input1).to receive(:failures).and_return([])
      allow(input2).to receive(:failures).and_return([])
    end

    context 'without fail_on_error' do
      let(:fail_on_error) { false }

      it 'continues' do
        expect(processor.truncated_markdown).to include('awesome markdown')
      end

      it 'logs the error' do
        expect { processor.truncated_markdown }.to output(/life sucks/).to_stdout
      end
    end

    context 'with fail_on_error' do
      let(:fail_on_error) { true }

      it 'raises error' do
        expect { processor.truncated_markdown }.to raise_error('life sucks')
      end
    end
  end
end
