# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/softdeleteable_components_examples"

module Decidim
  module Assemblies
    module Admin
      describe AssembliesController do
        routes { Decidim::Assemblies::AdminEngine.routes }

        let(:organization) { create(:organization) }
        let(:current_user) { create(:user, :confirmed, :admin, organization:) }
        let!(:assembly) do
          create(
            :assembly,
            :published,
            organization:
          )
        end

        before do
          request.env["decidim.current_organization"] = organization
          request.env["decidim.current_assembly"] = assembly
          sign_in current_user
        end

        describe "PATCH update" do
          let(:assembly_params) do
            {
              title: assembly.title,
              subtitle: assembly.subtitle,
              description: assembly.description,
              short_description: assembly.short_description,
              slug: assembly.slug,
              weight: assembly.weight
            }
          end

          it "uses the slug param as assembly id" do
            expect(AssemblyForm).to receive(:from_params).with(hash_including(id: assembly.id.to_s)).and_call_original

            patch :update, params: { slug: assembly.id, assembly: assembly_params }

            expect(response).to redirect_to(edit_assembly_path(assembly.slug))
          end
        end

        it_behaves_like "a soft-deletable space",
                        space_name: :assembly,
                        space_path: :assemblies_path,
                        trash_path: :manage_trash_assemblies_path
      end
    end
  end
end
