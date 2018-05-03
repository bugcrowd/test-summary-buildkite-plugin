# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Formatter do
  let(:show_first) { nil }
  let(:input) { double(TestSummaryBuildkitePlugin::Input::Base, label: 'animals') }
  let(:failures) { [] }

  subject(:markdown) { described_class.new(type: type, show_first: show_first).markdown(input) }

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

      context 'and job_id' do
        before { failures.first.job_id = 'awesome_job' }

        it 'includes the job_id' do
          expect(markdown).to include('awesome_job')
        end
      end
    end

    context 'with details' do
      let(:name) { 'ponies are awesome' }
      let(:details) { 'like, really awesome' }
      let(:failures) do
        [TestSummaryBuildkitePlugin::Failure::Structured.new(
          name: name,
          details: details
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

      context 'and job_id' do
        before { failures.first.job_id = 'awesome_job' }

        it 'includes the job_id' do
          expect(markdown).to include('awesome_job')
        end
      end

      context 'with html chars in name' do
        let(:name) { 'ponies are awesome <strong>&</strong> amazing' }

        it 'escapes angle brackets' do
          expect(markdown).to include('&lt;')
        end

        it 'escapes "&"' do
          expect(markdown).to include('&amp;')
        end
      end

      context 'with html chars in description' do
        let(:details) { 'like, really awesome <strong>&</strong> amazing' }

        it 'escapes angle brackets' do
          expect(markdown).to include('&lt;')
        end

        it 'escapes "&"' do
          expect(markdown).to include('&amp;')
        end
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
    let(:before_details) { markdown.split('<details').first }
    let(:after_details) { markdown.split('<details').last }

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
        expect(before_details).to include('dog', 'cat', 'pony')
        expect(before_details).not_to include('horse', 'unicorn')
      end

      it 'includes correct elements after details' do
        expect(after_details).not_to include('dog', 'cat', 'pony')
        expect(after_details).to include('horse', 'unicorn')
      end
    end

    context 'when zero' do
      let(:show_first) { 0 }

      it 'includes a details element' do
        expect(markdown).to include('<details')
      end

      it 'includes no elements before details' do
        expect(before_details).not_to include('dog', 'cat', 'pony', 'horse', 'unicorn')
      end

      it 'includes all elements after details' do
        expect(after_details).to include('dog', 'cat', 'pony', 'horse', 'unicorn')
      end
    end

    context 'when negative' do
      let(:show_first) { -1 }

      it 'has no details element' do
        expect(markdown).not_to include('<details')
      end
    end
  end

  describe 'unknown type' do
    let(:type) { 'foo' }

    it 'raises an exception' do
      expect { markdown }.to raise_error(/Unknown type/)
    end
  end

  describe 'with no formatter options' do
    subject(:markdown) { described_class.new.markdown(input) }
    let(:failures) do
      [TestSummaryBuildkitePlugin::Failure::Structured.new(
        name: 'ponies are awesome',
        details: 'like, really awesome'
      )]
    end

    it 'includes the details' do
      expect(markdown).to include('like, really awesome')
    end
  end
end
