# frozen_string_literal: true

module Decidim
  module Decidim-template
    # This is the engine that runs on the public interface of `Decidim-template`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Decidim-template::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        # resources :decidim-template do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "decidim-template#index"
      end

      def load_seed
        nil
      end
    end
  end
end
