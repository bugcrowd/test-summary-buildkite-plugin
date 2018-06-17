# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Truncater do
  let(:max_size) { 5000 }
  let(:input1) { double(TestSummaryBuildkitePlugin::Input::Base, label: 'animals') }
  let(:input2) { double(TestSummaryBuildkitePlugin::Input::Base, label: 'cars') }
  let(:inputs) { [input1, input2] }
  let(:failures1) do
    %w[dog cat pony horse unicorn].map { |x| TestSummaryBuildkitePlugin::Failure::Unstructured.new(x) }
  end
  let(:failures2) do
    %w[toyota honda holden ford mazda volkswagen].map { |x| TestSummaryBuildkitePlugin::Failure::Unstructured.new(x) }
  end
  let(:formatter_opts) { nil }
  let(:fail_on_error) { false }
  let(:options) { { max_size: max_size, inputs: inputs, formatter_opts: formatter_opts, fail_on_error: fail_on_error } }
  let(:truncater) { described_class.new(options) }

  subject(:truncated) { truncater.markdown }

  before do
    allow(input1).to receive(:failures).and_return(failures1)
    allow(input2).to receive(:failures).and_return(failures2)
  end

  context 'when no failures' do
    let(:failures1) { [] }
    let(:failures2) { [] }

    it 'returns nothing' do
      is_expected.to be_empty
    end
  end

  context 'when below max size' do
    let(:max_size) { 50_000 }

    it 'returns all failures' do
      is_expected.to include('dog', 'cat', 'pony', 'horse', 'unicorn')
      is_expected.to include('toyota', 'honda', 'holden', 'ford', 'mazda', 'volkswagen')
    end
  end

  context 'when above max size' do
    let(:max_size) { 400 }

    it 'returns something below max size' do
      expect(truncated.bytesize).to be <= max_size
    end

    it 'optimally truncates' do
      is_expected.to include('Showing first 4')
    end
  end

  context 'when optimization fails' do
    before do
      allow(truncater).to receive(:markdown_with_truncation).and_return('a' * (max_size + 1))
    end

    it 'shows a helpful error' do
      is_expected.to include('ANNOTATION ERROR')
    end
  end

  context 'formatter raises exceptions' do
    let(:formatter) { spy }

    before do
      allow(truncater).to receive(:formatter).and_return(formatter)
      allow(formatter).to receive(:markdown).with(input1).and_raise('life sucks')
      allow(formatter).to receive(:markdown).with(input2).and_return('awesome markdown')
    end

    context 'without fail_on_error' do
      it 'continues' do
        expect(truncated).to include('awesome markdown')
      end

      it 'logs the error' do
        expect { truncated }.to output(/life sucks/).to_stdout
      end
    end

    context 'with fail_on_error' do
      let(:fail_on_error) { true }

      it 'raises error' do
        expect { truncated }.to raise_error('life sucks')
      end
    end
  end
end
