# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe CreateProposal do
      let(:form_klass) { ProposalForm }
      let(:component) { create(:proposal_component) }
      let(:organization) { component.organization }
      let(:user) { create(:user, :admin, :confirmed, organization:) }
      let(:form) do
        form_klass.from_params(
          form_params
        ).with_context(
          current_user: user,
          current_organization: organization,
          current_participatory_space: component.participatory_space,
          current_component: component
        )
      end

      let(:author) { create(:user, organization:) }

      describe "call" do
        let(:form_params) do
          {
            title: "A reasonable proposal title",
            body: "A reasonable proposal body"
          }
        end

        let(:command) do
          described_class.new(form, author)
        end

        describe "when the form is not valid" do
          before do
            allow(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "does not create a proposal" do
            expect do
              command.call
            end.not_to change(Decidim::Proposals::Proposal, :count)
          end
        end

        describe "when the form is valid" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it_behaves_like "fires an ActiveSupport::Notification event", "decidim.proposals.create_proposal:before"
          it_behaves_like "fires an ActiveSupport::Notification event", "decidim.proposals.create_proposal:after"

          it "creates a new proposal" do
            expect do
              command.call
            end.to change(Decidim::Proposals::Proposal, :count).by(1)
          end

          it "sets the body and title as i18n" do
            command.call
            proposal = Decidim::Proposals::Proposal.last

            expect(proposal.title).to be_a(Hash)
            expect(proposal.title[I18n.locale.to_s]).to eq form_params[:title]
            expect(proposal.body).to be_a(Hash)
            expect(proposal.body[I18n.locale.to_s]).to eq form_params[:body]
          end

          it "does not create a searchable resource" do
            command.call

            expect { command.call }.not_to change(Decidim::SearchableResource, :count)
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with(
                :create,
                Decidim::Proposals::Proposal,
                author,
                visibility: "public-only"
              ).and_call_original

            expect { described_class.call(form, author) }.to change(Decidim::ActionLog, :count).by(1)
          end

          context "with an author" do
            it "sets the author" do
              command.call
              proposal = Decidim::Proposals::Proposal.last
              creator = proposal.creator

              expect(creator.author).to eq(author)
            end

            it "adds the author as a follower" do
              command.call
              proposal = Decidim::Proposals::Proposal.last

              expect(proposal.followers).to include(author)
            end

            context "with a proposal limit" do
              let(:component) do
                create(:proposal_component, settings: { "proposal_limit" => 2 })
              end

              it "checks the author does not exceed the amount of proposals" do
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:invalid)
              end
            end
          end

          describe "the proposal limit excludes withdrawn proposals" do
            let(:component) do
              create(:proposal_component, settings: { "proposal_limit" => 1 })
            end

            describe "when the author is a user" do
              before do
                create(:proposal, :withdrawn, users: [author], component:)
              end

              it "checks the user does not exceed the amount of proposals" do
                expect { command.call }.to broadcast(:ok)
                expect { command.call }.to broadcast(:invalid)

                user_proposal_count = Decidim::Coauthorship.where(author:, coauthorable_type: "Decidim::Proposals::Proposal").count
                expect(user_proposal_count).to eq(2)
              end
            end
          end
        end
      end
    end
  end
end
