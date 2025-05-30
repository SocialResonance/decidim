# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test"
require "decidim/sortitions/test/factories"

describe "Decidim::Api::QueryType" do
  include_context "with a graphql decidim component" do
    let(:component_fragment) do
      %(
      fragment fooComponent on Sortitions {
        sortition(id: #{sortition.id}){
          acceptsNewComments
          additionalInfo {  translation(locale: "#{locale}") }
          author { id }
          cancelReason { translation(locale: "#{locale}") }
          cancelledByUser { id }
          cancelledOn
          candidateProposals
          taxonomies { id }
          comments { id }
          commentsHaveAlignment
          commentsHaveVotes
          createdAt
          dice
          hasComments
          id
          reference
          requestTimestamp
          selectedProposals
          targetItems
          title { translation(locale: "#{locale}") }
          totalCommentsCount
          type
          updatedAt
          url
          userAllowedToComment
          witnesses { translation(locale: "#{locale}") }
        }
      }
    )
    end
  end
  let(:component_type) { "Sortitions" }
  let!(:current_component) { create(:sortition_component, participatory_space: participatory_process) }
  let(:author) { create(:user, :confirmed, :admin, organization: current_component.organization) }
  let!(:sortition) { create(:sortition, component: current_component, taxonomies:, author:) }

  let(:sortition_single_result) do
    sortition.reload
    {
      "acceptsNewComments" => sortition.accepts_new_comments?,
      "additionalInfo" => { "translation" => sortition.additional_info[locale] },
      "author" => { "id" => sortition.author.id.to_s },
      "cancelReason" => sortition.cancel_reason,
      "cancelledByUser" => sortition.cancelled_by_user,
      "cancelledOn" => sortition.cancelled_on,
      "candidateProposals" => sortition.candidate_proposals,
      "taxonomies" => [{ "id" => sortition.taxonomies.first.id.to_s }],
      "comments" => [],
      "commentsHaveAlignment" => sortition.comments_have_alignment?,
      "commentsHaveVotes" => sortition.comments_have_votes?,
      "createdAt" => sortition.created_at.to_time.iso8601,
      "dice" => sortition.dice,
      "hasComments" => sortition.comment_threads.size.positive?,
      "id" => sortition.id.to_s,
      "reference" => sortition.reference,
      "requestTimestamp" => sortition.request_timestamp.to_time.iso8601,
      "selectedProposals" => sortition.selected_proposals,
      "targetItems" => sortition.target_items,
      "title" => { "translation" => sortition.title[locale] },
      "totalCommentsCount" => sortition.comments_count,
      "type" => "Decidim::Sortitions::Sortition",
      "updatedAt" => sortition.updated_at.to_time.iso8601,
      "url" => Decidim::ResourceLocatorPresenter.new(sortition).url,
      "userAllowedToComment" => sortition.user_allowed_to_comment?(current_user),
      "witnesses" => { "translation" => sortition.witnesses[locale] }
    }
  end

  let(:sortition_data) do
    {
      "__typename" => "Sortitions",
      "id" => current_component.id.to_s,
      "name" => { "translation" => translated(current_component.name) },
      "sortitions" => {
        "edges" => [
          {
            "node" => sortition_single_result
          }
        ]
      },
      "url" => Decidim::EngineRouter.main_proxy(current_component).root_url,
      "weight" => 0
    }
  end

  describe "commentable" do
    let(:component_fragment) { nil }
    let(:participatory_process_query) do
      %(
        commentable(id: "#{sortition.id}", type: "Decidim::Sortitions::Sortition", locale: "en", toggleTranslations: false) {
          __typename
        }
      )
    end

    it "executes successfully" do
      expect { response }.not_to raise_error
    end

    it do
      expect(response).to eq({ "commentable" => { "__typename" => "Sortition" } })
    end
  end

  describe "valid connection query" do
    let(:component_fragment) do
      %(
        fragment fooComponent on Sortitions {
          sortitions {
            edges{
              node{
                acceptsNewComments
                additionalInfo {  translation(locale: "#{locale}") }
                author { id }
                cancelReason { translation(locale: "#{locale}") }
                cancelledByUser { id }
                cancelledOn
                candidateProposals
                taxonomies { id }
                comments { id }
                commentsHaveAlignment
                commentsHaveVotes
                createdAt
                dice
                hasComments
                id
                reference
                requestTimestamp
                selectedProposals
                targetItems
                title { translation(locale: "#{locale}") }
                totalCommentsCount
                type
                updatedAt
                url
                userAllowedToComment
                witnesses { translation(locale: "#{locale}") }
              }
            }
          }
        }
      )
    end

    it "executes successfully" do
      expect { response }.not_to raise_error
    end

    it { expect(response["participatoryProcess"]["components"].first).to eq(sortition_data) }
  end

  describe "valid query" do
    it "executes successfully" do
      expect { response }.not_to raise_error
    end

    it { expect(response["participatoryProcess"]["components"].first["sortition"]).to eq(sortition_single_result) }
  end

  include_examples "with resource visibility" do
    let(:component_factory) { :sortition_component }
    let(:lookout_key) { "sortition" }
    let(:query_result) { sortition_single_result }
  end
end
