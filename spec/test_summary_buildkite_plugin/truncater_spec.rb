# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Truncater do
  let(:max_size) { 400 }
  let(:truncater) { described_class.new(max_size: max_size, max_truncate: 200, &blk) }

  subject(:truncated) { truncater.markdown }

  context 'when empty string' do
    let(:blk) { Proc.new { '' } } # rubocop:disable Style/Proc

    it 'returns nothing' do
      is_expected.to be_empty
    end
  end

  context 'when below max size' do
    let(:blk) { Proc.new { 'foo' } } # rubocop:disable Style/Proc

    it 'returns all failures' do
      is_expected.to eq('foo')
    end
  end

  context 'when above max size' do
    let(:blk) { Proc.new { |truncate| 'foo' * (truncate || max_size) } } # rubocop:disable Style/Proc

    it 'returns something below max size' do
      expect(truncated.bytesize).to be <= max_size
    end

    it 'optimally truncates' do
      is_expected.to eq('foo' * 133) # 399 characters
    end
  end

  context 'when optimization fails' do
    let(:blk) { Proc.new { 'foo' * max_size } } # rubocop:disable Style/Proc

    it 'returns nil' do
      is_expected.to be_nil
    end
  end
end
