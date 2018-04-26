# frozen_string_literal: true

module Stubs
  def self.included(base)
    attr_accessor :agent_commands

    base.before do
      allow(TestSummaryBuildkitePlugin::Agent.instance).to receive(:run) do |*args|
        @agent_commands ||= []
        @agent_commands << args
      end

      stub_const('TestSummaryBuildkitePlugin::Input::WORKDIR', 'spec/sample_artifacts')
    end
  end
end
