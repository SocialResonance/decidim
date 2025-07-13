# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module Factory
    # This is the engine that runs on the public interface of factory.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Factory

      routes do
        # Add engine routes here
        # resources :factory
        # root to: "factory#index"
      end

      initializer "Factory.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
