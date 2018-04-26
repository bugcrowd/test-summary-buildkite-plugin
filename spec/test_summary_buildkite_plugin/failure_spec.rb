# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Failure do
  describe TestSummaryBuildkitePlugin::Failure::Structured do
    let(:file) { 'foo.rb' }
    let(:line) { 123 }
    let(:column) { 79 }
    let(:name) { 'unicorns are\'t real' }
    let(:details) { 'This is a failure of great proportions' }
    let(:params) { { file: file, line: line, column: column, name: name, details: details } }

    describe 'summary' do
      subject(:summary) { described_class.new(params).summary }

      it 'includes name' do
        expect(summary).to include(name)
      end

      it 'does not include details' do
        expect(summary).not_to include(details)
      end

      context 'with file, line and column' do
        it { expect(summary).to start_with("#{file}:#{line}:#{column}: ") }
      end

      context 'with only file and line' do
        let(:column) { nil }

        it { expect(summary).to start_with("#{file}:#{line}: ") }
      end

      context 'with only file' do
        let(:line) { nil }
        let(:column) { nil }

        it { expect(summary).to start_with("#{file}: ") }
      end

      context 'with no location information' do
        let(:file) { nil }
        let(:line) { nil }
        let(:column) { nil }

        it { expect(summary).to eq(name) }
      end
    end

    describe 'strip_colors' do
      let(:details) { 'Failure/Error: \\e[0m\\e[32mit\\e[0m { \\e[32mexpect\\e[0m(url).to be_nil }' }

      subject(:failure) { described_class.new(params) }

      before { failure.strip_colors }

      it 'strips terminal color directives' do
        expect(failure.details).to eq('Failure/Error: it { expect(url).to be_nil }')
      end
    end
  end
end
