# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Tap do
  subject(:suite) { described_class::Parser.new(text).parse }

  context 'sane version 12' do
    let(:text) { "not ok 17 - failure\nok 18 - yay" }

    it 'is version 12' do
      expect(suite).to have_attributes(version: 12)
    end

    it 'contains the tests' do
      expect(suite.tests).to(match_array([
                                           have_attributes(passed: false, description: 'failure'),
                                           have_attributes(passed: true, description: 'yay')
                                         ]))
    end
  end

  context 'sane version 13' do
    let(:text) { "TAP version 13\nnot ok 10 failure\nok 18 - yay" }

    it 'is version 13' do
      expect(suite).to have_attributes(version: 13)
    end

    it 'contains the tests' do
      expect(suite.tests).to(match_array([
                                           have_attributes(passed: false, description: 'failure'),
                                           have_attributes(passed: true, description: 'yay')
                                         ]))
    end
  end

  context 'with todo tests' do
    let(:text) { 'not ok be awesome # TODO get around to this' }

    it 'is handled correctly' do
      expect(suite.tests.first).to have_attributes(
        passed: false,
        description: 'be awesome',
        directive: 'TODO get around to this',
        todo: be_truthy,
        skipped: be_falsey
      )
    end
  end

  context 'with skipped tests' do
    let(:text) { 'not ok be awesome # SKIP get around to this' }

    it 'is handled correctly' do
      expect(suite.tests.first).to have_attributes(
        passed: false,
        description: 'be awesome',
        directive: 'SKIP get around to this',
        todo: be_falsey,
        skipped: be_truthy
      )
    end
  end

  context 'with lowercase skipped tests' do
    let(:text) { 'not ok be awesome # skipped get around to this' }

    it 'is handled correctly' do
      expect(suite.tests.first).to have_attributes(
        passed: false,
        description: 'be awesome',
        directive: 'skipped get around to this',
        todo: be_falsey,
        skipped: be_truthy
      )
    end
  end

  context 'with indented directives' do
    let(:text) { "not ok be awesome\n#  two\n#    four" }

    it 'unindents' do
      expect(suite.tests.first).to have_attributes(diagnostic: "two\n  four")
    end
  end

  context 'with yaml' do
    let(:text) { "not ok be awesome\n    ---\n    one:\n        two\n     ..." }

    it 'unindents' do
      expect(suite.tests.first).to have_attributes(yaml: "one:\n    two")
    end
  end
end
