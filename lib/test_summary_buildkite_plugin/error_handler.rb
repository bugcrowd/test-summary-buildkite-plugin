# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module ErrorHandler
    def handle_error(err, diagnostics = nil)
      if fail_on_error
        raise err
      else
        Utils.log_error(err, diagnostics)
      end
    end
  end
end
