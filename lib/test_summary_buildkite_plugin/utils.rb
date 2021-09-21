# frozen_string_literal: true

require 'kramdown'

module TestSummaryBuildkitePlugin
  module Utils
    def self.log_error(err, diagnostics = nil)
      puts "#{err.class}: #{err.message}\n\n#{err.backtrace.join("\n")}"
      puts
      puts 'Please report this to https://github.com/bugcrowd/test-summary-buildkite-plugin/issues'
      puts 'with the log above and the details below, if present.'
      puts JSON.pretty_generate(diagnostics) unless diagnostics.nil?
    end

    def self.standalone_markdown(markdown)
      content = Kramdown::Document.new(markdown).to_html
      HamlRender.render('standalone_layout', content: content)
    end
  end
end
