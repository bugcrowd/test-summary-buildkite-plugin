# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  module Utils
    def log_error(err)
      puts "#{err.class}: #{err.message}\n\n#{err.backtrace.join("\n")}"
    end

    module_function :log_error
  end
end
