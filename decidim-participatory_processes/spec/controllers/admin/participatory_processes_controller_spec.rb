# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/softdeleteable_components_examples"

module Decidim
  module ParticipatoryProcesses
    module Admin
      describe ParticipatoryProcessesController do
        routes { Decidim::ParticipatoryProcesses::AdminEngine.routes }

        let(:organization) { create(:organization) }
        let(:current_user) { create(:user, :confirmed, :admin, organization:) }
        let!(:participatory_process) do
          create(
            :participatory_process,
            :published,
            organization:
          )
        end

        before do
          request.env["decidim.current_organization"] = organization
          request.env["decidim.current_participatory_process"] = participatory_process
          sign_in current_user
        end

        describe "PATCH update" do
          let(:participatory_process_params) do
            {
              title: participatory_process.title,
              subtitle: participatory_process.subtitle,
              weight: participatory_process.weight,
              description: participatory_process.description,
              short_description: participatory_process.short_description,
              slug: participatory_process.slug
            }
          end

          it "uses the slug param as participatory_process id" do
            expect(ParticipatoryProcessForm).to receive(:from_params).with(hash_including(id: participatory_process.id.to_s)).and_call_original

            patch :update, params: { slug: participatory_process.id, participatory_process: participatory_process_params }

            expect(response).to redirect_to(edit_participatory_process_path(participatory_process.slug))
          end
        end

        it_behaves_like "a soft-deletable space",
                        space_name: :participatory_process,
                        space_path: :participatory_processes_path,
                        trash_path: :manage_trash_participatory_processes_path
      end
    end
  end
end
