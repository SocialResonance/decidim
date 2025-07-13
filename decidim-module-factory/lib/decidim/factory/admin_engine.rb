# frozen_string_literal: true

module Decidim
  module Factory
    # This is the engine that runs on the public interface of `Factory`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Factory::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        # resources :factory do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "factory#index"
      end

      def load_seed
        nil
      end
    end
  end
end
