# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class HamlRender
    def self.render(name, params, folder: nil)
      filename = %W[templates/#{folder}/#{name}.html.haml templates/#{name}.html.haml].find { |f| File.exist?(f) }
      if filename
        engine = Haml::Engine.new(File.read(filename), escape_html: true)
        engine.render(Object.new, params)
      end
    end
  end
end
