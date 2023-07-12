# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Failure do
  describe TestSummaryBuildkitePlugin::Failure::Structured do
    let(:summary) { 'foo.rb: unicorns are\'t real' }
    let(:details) { 'This is a failure of great proportions' }
    let(:params) { { summary: summary, details: details } }

    describe 'strip_colors' do
      let(:details) { 'Failure/Error: \\e[0m\\e[32mit\\e[0m { \\e[32mexpect\\e[0m(url).to be_nil }' }

      subject(:failure) { described_class.new(**params) }

      before { failure.strip_colors }

      it 'strips terminal color directives' do
        expect(failure.details).to eq('Failure/Error: it { expect(url).to be_nil }')
      end
    end
  end
end
