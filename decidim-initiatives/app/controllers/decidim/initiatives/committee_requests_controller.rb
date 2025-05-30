# frozen_string_literal: true

module Decidim
  module Initiatives
    # Controller in charge of managing committee membership
    class CommitteeRequestsController < Decidim::Initiatives::ApplicationController
      include Decidim::Initiatives::NeedsInitiative

      helper InitiativeHelper
      helper Decidim::ActionAuthorizationHelper

      # GET /initiatives/:initiative_id/committee_requests/new
      def new
        enforce_permission_to :request_membership, :initiative, initiative: current_initiative
      end

      # GET /initiatives/:initiative_id/committee_requests/spawn
      def spawn
        enforce_permission_to :request_membership, :initiative, initiative: current_initiative

        form = Decidim::Initiatives::CommitteeMemberForm
               .from_params(initiative_id: current_initiative.id, user_id: current_user.id, state: "requested")
               .with_context(current_organization: current_initiative.organization, current_user:)

        SpawnCommitteeRequest.call(form) do
          on(:ok) do
            redirect_to initiatives_path, flash: {
              notice: I18n.t(
                "success",
                scope: "decidim.initiatives.committee_requests.spawn"
              )
            }
          end

          on(:invalid) do |request|
            redirect_to initiatives_path, flash: {
              error: request.errors.full_messages.to_sentence
            }
          end
        end
      end

      # GET /initiatives/:initiative_id/committee_requests/:id/approve
      def approve
        enforce_permission_to :approve, :initiative_committee_member, request: membership_request

        ApproveMembershipRequest.call(membership_request) do
          on(:ok) do
            redirect_to redirect_page, flash: {
              notice: I18n.t("success", scope: "decidim.initiatives.committee_requests.approve")
            }
          end
        end
      end

      # DELETE /initiatives/:initiative_id/committee_requests/:id/revoke
      def revoke
        enforce_permission_to :revoke, :initiative_committee_member, request: membership_request

        RevokeMembershipRequest.call(membership_request) do
          on(:ok) do
            redirect_to redirect_page, flash: {
              notice: I18n.t("success", scope: "decidim.initiatives.committee_requests.revoke")
            }
          end
        end
      end

      private

      def redirect_page
        if request.referer&.include?("create_initiative")
          promotal_committee_create_initiative_index_path
        else
          edit_initiative_path(current_initiative)
        end
      end

      def membership_request
        @membership_request ||= InitiativesCommitteeMember.where(initiative: current_participatory_space).find(params[:id])
      end
    end
  end
end
