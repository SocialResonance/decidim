# frozen_string_literal: true

module Decidim
  module Proposals
    module AdminLog
      # This class holds the logic to present a `Decidim::Proposals::Proposal`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you should not need to call this class
      # directly, but here is an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    ProposalPresenter.new(action_log, view_helpers).present
      class ProposalPresenter < Decidim::Log::BasePresenter
        def initialize(action_log, view_helpers)
          super
          @proposal = action_log.resource if action_log.resource
        end

        private

        attr_reader :proposal

        def diff_fields_mapping
          {
            title: :i18n,
            body: "Decidim::Proposals::AdminLog::ValueTypes::ProposalTitleBodyPresenter",
            state: "Decidim::Proposals::AdminLog::ValueTypes::ProposalStatePresenter",
            answered_at: :date,
            answer: :i18n
          }
        end

        def i18n_params
          super.merge(merged_count:)
        end

        def action_string
          case action
          when "answer", "create", "update", "publish_answer", "soft_delete", "restore"
            "decidim.proposals.admin_log.proposal.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.proposal"
        end

        def diff_actions
          super + %w(answer)
        end

        def merged_count
          proposal&.linked_resources(:proposals, "merged_from_component")&.count || 0
        end
      end
    end
  end
end
