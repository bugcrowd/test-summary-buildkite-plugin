# frozen_string_literal: true

module Stubs
  def self.included(base)
    base.before do
      allow(TestSummaryBuildkitePlugin::Agent.instance).to receive(:run) do |*args|
        @agent_commands ||= []
        @agent_commands << args
      end

      stub_const('TestSummaryBuildkitePlugin::Input::WORKDIR', 'spec/sample_artifacts')
    end
  end

  def agent_commands
    @agent_commands || []
  end

  def agent_artifact_commands
    agent_commands.select { |x| x.first == 'artifact' }
  end

  def agent_annotate_commands
    agent_commands.select { |x| x.first == 'annotate' }
  end
end
