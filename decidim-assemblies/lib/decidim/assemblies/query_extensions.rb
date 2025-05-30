# frozen_string_literal: true

module Decidim
  module Assemblies
    # This module's job is to extend the API with custom fields related to
    # decidim-assemblies.
    module QueryExtensions
      # Public: Extends a type with `decidim-assemblies`'s fields.
      #
      # type - A GraphQL::BaseType to extend.
      #
      # Returns nothing.
      def self.included(type)
        type.field :assemblies,
                   [Decidim::Assemblies::AssemblyType],
                   null: true,
                   description: "Lists all assemblies" do
          argument :filter, Decidim::ParticipatoryProcesses::ParticipatoryProcessInputFilter, "This argument lets you filter the results", required: false
          argument :order, Decidim::ParticipatoryProcesses::ParticipatoryProcessInputSort, "This argument lets you order the results", required: false
        end

        type.field :assembly,
                   Decidim::Assemblies::AssemblyType,
                   null: true,
                   description: "Finds an assembly" do
          argument :id, GraphQL::Types::ID, "The ID of the participatory space", required: false
        end
      end

      def assemblies(filter: {}, order: {})
        manifest = Decidim.participatory_space_manifests.select { |m| m.name == :assemblies }.first
        Decidim::Core::ParticipatorySpaceListBase.new(manifest:).call(object, { filter:, order: }, context)
      end

      def assembly(id: nil)
        manifest = Decidim.participatory_space_manifests.select { |m| m.name == :assemblies }.first
        Decidim::Core::ParticipatorySpaceFinderBase.new(manifest:).call(object, { id: }, context)
      end
    end
  end
end
