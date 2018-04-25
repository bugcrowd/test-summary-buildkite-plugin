# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Formatter do
  let(:show_first) { nil }
  let(:input) { double(TestSummaryBuildkitePlugin::Input::Base, label: 'animals') }
  let(:failures) { [] }

  subject(:markdown) { described_class.create(type: type, show_first: show_first).markdown(input) }

  before do
    allow(input).to receive(:failures).and_return(failures)
  end

  describe 'details' do
    let(:type) { 'details' }

    context 'with no failures' do
      let(:failures) { [] }

      it 'returns empty markdown' do
        expect(markdown).to be_nil
      end
    end

    context 'with no details' do
      let(:failures) { [TestSummaryBuildkitePlugin::Failure::Unstructured.new('ponies are awesome')] }

      it 'includes the label' do
        expect(markdown).to include('animals')
      end
      it 'includes the summary' do
        expect(markdown).to include('ponies are awesome')
      end

      it 'has no <details> elements' do
        expect(markdown).not_to include('<details')
      end
    end

    context 'with details' do
      let(:failures) do
        [TestSummaryBuildkitePlugin::Failure::Structured.new(
          name: 'ponies are awesome',
          details: 'like, really awesome'
        )]
      end

      it 'includes the summary' do
        expect(markdown).to include('ponies are awesome')
      end

      it 'includes the details' do
        expect(markdown).to include('like, really awesome')
      end

      it 'has a <details> element' do
        expect(markdown).to include('<details')
      end
    end
  end

  describe 'summary' do
    let(:type) { 'summary' }

    context 'with no failures' do
      let(:failures) { [] }

      it 'returns empty markdown' do
        expect(markdown).to be_nil
      end
    end

    context 'with failures' do
      let(:failures) { [TestSummaryBuildkitePlugin::Failure::Unstructured.new('ponies are awesome')] }

      it 'includes the label' do
        expect(markdown).to include('animals')
      end
      it 'includes the summary' do
        expect(markdown).to include('ponies are awesome')
      end
    end
  end

  describe 'show_first' do
    let(:type) { 'summary' }
    let(:show_first) { 2 }
    let(:failures) do
      %w[dog cat pony horse unicorn].map { |x| TestSummaryBuildkitePlugin::Failure::Unstructured.new(x) }
    end

    context 'when larger than failure count' do
      let(:show_first) { 10 }

      it 'has no details element' do
        expect(markdown).not_to include('<details')
      end
    end

    context 'when smaller than failure count' do
      let(:show_first) { 3 }

      it 'includes a details element' do
        expect(markdown).to include('<details')
      end

      it 'includes correct elements before details' do
        expect(markdown.split('<details').first).to include('dog')
        expect(markdown.split('<details').first).to include('cat')
        expect(markdown.split('<details').first).to include('pony')
        expect(markdown.split('<details').first).not_to include('horse')
        expect(markdown.split('<details').first).not_to include('unicorn')
      end

      it 'includes correct elements after details' do
        expect(markdown.split('<details').last).not_to include('dog')
        expect(markdown.split('<details').last).not_to include('cat')
        expect(markdown.split('<details').last).not_to include('pony')
        expect(markdown.split('<details').last).to include('horse')
        expect(markdown.split('<details').last).to include('unicorn')
      end
    end
  end
end
