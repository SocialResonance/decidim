# frozen_string_literal: true

require "decidim/generators/component_generator"

module Decidim
  module ModuleFactory
    class Generator < Decidim::Generators::ComponentGenerator
      source_root File.expand_path("templates", __dir__)

      def self.banner
        "decidim-module-factory --module-factory NAME [options]"
      end

      desc "component NAME", "Generate a decidim component with AI rules"
      def component(name)
        super
        template "rules.md.tt", "decidim-#{name}/docs/rules.md"
      end
    end
  end
end
