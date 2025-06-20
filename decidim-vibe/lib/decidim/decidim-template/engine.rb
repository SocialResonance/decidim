# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module Decidim-template
    # This is the engine that runs on the public interface of decidim-template.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Decidim-template

      routes do
        # Add engine routes here
        # resources :decidim-template
        # root to: "decidim-template#index"
      end

      initializer "Decidim-template.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
