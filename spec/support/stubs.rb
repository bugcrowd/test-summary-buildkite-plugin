# frozen_string_literal: true

module Stubs
  def self.included(base)
    base.before do
      TestSummaryBuildkitePlugin::Agent.stub = true
      stub_const('TestSummaryBuildkitePlugin::Input::WORKDIR', 'spec/sample_artifacts')
    end

    base.after do
      TestSummaryBuildkitePlugin::Agent.stub = false
    end
  end
end
