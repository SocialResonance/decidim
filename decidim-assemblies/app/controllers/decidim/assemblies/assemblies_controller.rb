# frozen_string_literal: true

module Decidim
  module Assemblies
    # A controller that holds the logic to show Assemblies in a public layout.
    class AssembliesController < Decidim::Assemblies::ApplicationController
      include ParticipatorySpaceContext
      include AssemblyBreadcrumb
      include FilterResource
      include Paginable
      include HasParticipatorySpaceContentBlocks

      helper_method :collection, :parent_assemblies, :promoted_assemblies, :stats, :assembly_participatory_processes

      def index
        enforce_permission_to :list, :assembly

        respond_to do |format|
          format.html do
            raise ActionController::RoutingError, "Not Found" if published_assemblies.none?

            render "index"
          end

          format.js do
            raise ActionController::RoutingError, "Not Found" if published_assemblies.none?

            render "index"
          end

          format.json do
            render json: published_assemblies.query.includes(:children).where(parent: nil).collect { |assembly|
              {
                name: assembly.title[I18n.locale.to_s],
                children: assembly.children.collect do |child|
                  {
                    name: child.title[I18n.locale.to_s],
                    children: child.children.collect { |child_of_child| { name: child_of_child.title[I18n.locale.to_s] } }
                  }
                end
              }
            }
          end
        end
      end

      def show
        enforce_permission_to :read, :assembly, assembly: current_participatory_space
      end

      private

      def search_collection
        published_assemblies.query
      end

      def default_filter_params
        {
          with_any_taxonomies: nil
        }
      end

      def current_participatory_space
        return unless params[:slug]

        @current_participatory_space ||= OrganizationAssemblies.new(current_organization).query.where(slug: params[:slug]).or(
          OrganizationAssemblies.new(current_organization).query.where(id: params[:slug])
        ).first!
      end

      def published_assemblies
        @published_assemblies ||= OrganizationPublishedAssemblies.new(current_organization, current_user)
      end

      def promoted_assemblies
        @promoted_assemblies ||= published_assemblies | PromotedAssemblies.new
      end

      def parent_assemblies
        search.result.parent_assemblies.order(weight: :asc, promoted: :desc)
      end

      def collection
        @collection ||= paginate(Kaminari.paginate_array(parent_assemblies))
      end

      def stats
        @stats ||= AssemblyStatsPresenter.new(assembly: current_participatory_space)
      end

      def assembly_participatory_processes
        @assembly_participatory_processes ||= @current_participatory_space.linked_participatory_space_resources(:participatory_processes, "included_participatory_processes")
      end
    end
  end
end
