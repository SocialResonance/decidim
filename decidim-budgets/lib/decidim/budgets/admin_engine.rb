# frozen_string_literal: true

module Decidim
  module Budgets
    # This is the engine that runs on the public interface of `decidim-budgets`.
    # It mostly handles rendering the created projects associated to a participatory
    # process.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Budgets::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :budgets do
          collection do
            get :manage_trash
          end

          member do
            patch :soft_delete
            patch :restore
          end

          resources :projects do
            collection do
              post :update_taxonomies
              post :update_selected
              post :update_budget
              resource :proposals_import, only: [:new, :create]
              get :manage_trash
            end

            member do
              patch :soft_delete
              patch :restore
            end
          end
        end

        resources :projects, exclude: [:index, :new, :create, :edit, :update, :destroy] do
          get :proposals_picker, on: :collection

          resources :attachment_collections, except: [:show]
          resources :attachments, except: [:show]
        end

        root to: "budgets#index"
      end

      def load_seed
        nil
      end
    end
  end
end
