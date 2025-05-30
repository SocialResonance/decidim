# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe VoteInitiative do
      let(:form_klass) { Decidim::Initiatives::SignatureHandler }
      let(:organization) { create(:organization) }
      let(:initiative) { create(:initiative, organization:) }

      let(:current_user) { create(:user, organization: initiative.organization) }
      let(:form) do
        form_klass
          .from_params(
            form_params
          ).with_context(current_organization: organization)
      end

      let(:form_params) do
        {
          initiative:,
          user: current_user
        }
      end

      let(:document_number) { "0123456789X" }
      let(:personal_data_params) do
        {
          name_and_surname: ::Faker::Name.name,
          document_type: Decidim::Verifications.document_types.first,
          document_number:,
          date_of_birth: ::Faker::Date.birthday(min_age: 18, max_age: 40),
          postal_code: ::Faker::Address.zip_code,
          scope_id: initiative.scope.id,
          gender: DummySignatureHandler::AVAILABLE_GENDERS.last
        }
      end

      describe "User votes initiative" do
        context "when initiative signature form does not require extra user fields" do
          let(:command) { described_class.new(form) }

          it "broadcasts ok" do
            expect { command.call }.to broadcast :ok
          end

          it "creates a vote" do
            expect do
              command.call
            end.to change(InitiativesVote, :count).by(1)
          end

          it "increases the vote counter by one" do
            expect do
              command.call
              initiative.reload
            end.to change(initiative, :online_votes_count).by(1)
          end

          it "notifies the creation" do
            follower = create(:user, organization: initiative.organization)
            create(:follow, followable: initiative.author, user: follower)

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.initiatives.initiative_liked",
                event_class: Decidim::Initiatives::LikeInitiativeEvent,
                resource: initiative,
                followers: [follower]
              )

            command.call
          end

          it "sends notification with email" do
            follower = create(:user, organization: initiative.organization)
            create(:follow, followable: initiative.author, user: follower)

            expect do
              perform_enqueued_jobs { command.call }
            end.to change(emails, :count).by(2)

            expect(last_email_body).to include("has liked the following initiative")
          end

          context "when a new milestone is completed" do
            let(:initiative) do
              create(:initiative,
                     organization:,
                     scoped_type: create(
                       :initiatives_type_scope,
                       supports_required: 4,
                       type: create(:initiatives_type, organization:)
                     ))
            end

            let!(:follower) { create(:user, organization: initiative.organization) }
            let!(:follow) { create(:follow, followable: initiative, user: follower) }

            before do
              create(:initiative_user_vote, initiative:)
              create(:initiative_user_vote, initiative:)
            end

            it "notifies the followers" do
              expect(Decidim::EventsManager).to receive(:publish)
                .with(kind_of(Hash))

              expect(Decidim::EventsManager)
                .to receive(:publish)
                .with(
                  event: "decidim.events.initiatives.milestone_completed",
                  event_class: Decidim::Initiatives::MilestoneCompletedEvent,
                  resource: initiative,
                  affected_users: [initiative.author],
                  followers: [follower],
                  extra: { percentage: 75 }
                )

              command.call
            end

            it "sends notification with email" do
              expect do
                perform_enqueued_jobs { command.call }
              end.to change(emails, :count).by(3)

              expect(last_email_body).to include("has achieved the 75% of signatures")
            end
          end

          context "when support threshold is reached" do
            let!(:admin) { create(:user, :admin, :confirmed, organization:) }
            let(:initiative) do
              create(:initiative,
                     organization:,
                     scoped_type: create(
                       :initiatives_type_scope,
                       supports_required: 4,
                       type: create(:initiatives_type, organization:)
                     ))
            end

            before do
              create(:initiative_user_vote, initiative:)
              create(:initiative_user_vote, initiative:)
              create(:initiative_user_vote, initiative:)
            end

            it "notifies the admins" do
              expect(Decidim::EventsManager).to receive(:publish)
                .with(kind_of(Hash)).twice

              expect(Decidim::EventsManager)
                .to receive(:publish)
                .with(
                  event: "decidim.events.initiatives.support_threshold_reached",
                  event_class: Decidim::Initiatives::Admin::SupportThresholdReachedEvent,
                  resource: initiative,
                  followers: [admin]
                )

              command.call
            end

            it "sends notification with email" do
              expect do
                perform_enqueued_jobs { command.call }
              end.to change(emails, :count).by(3)

              expect(last_email_body).to include("has reached the signatures threshold")
            end

            context "when more votes are added" do
              before do
                create(:initiative_user_vote, initiative:)
              end

              it "does not notifies the admins" do
                expect(Decidim::EventsManager).to receive(:publish)
                  .with(kind_of(Hash)).once

                expect(Decidim::EventsManager)
                  .not_to receive(:publish)
                  .with(
                    event: "decidim.events.initiatives.support_threshold_reached",
                    event_class: Decidim::Initiatives::Admin::SupportThresholdReachedEvent,
                    resource: initiative,
                    followers: [admin]
                  )

                expect do
                  perform_enqueued_jobs { command.call }
                end.to change(emails, :count).by(1)
              end
            end
          end
        end

        context "when initiative signature form requires extra user fields" do
          let(:form_klass) { DummySignatureHandler }
          let(:initiative) do
            create(
              :initiative,
              :with_user_extra_fields_collection,
              organization:
            )
          end
          let(:form_with_personal_data) do
            form_klass.from_params(form_params.merge(personal_data_params)).with_context(current_organization: organization)
          end

          let(:invalid_command) { described_class.new(form) }
          let(:command_with_personal_data) { described_class.new(form_with_personal_data) }

          it "broadcasts invalid when form does not contain personal data" do
            expect { invalid_command.call }.to broadcast :invalid
          end

          context "when another signature exists with the same hash_id" do
            before do
              create(:initiative_user_vote, initiative:, hash_id: form_with_personal_data.hash_id)
            end

            it "broadcasts invalid" do
              expect { command_with_personal_data.call }.to broadcast :invalid
            end
          end

          context "when initiative type has signature workflow handler including an authorization handler" do
            let(:workflow_name) { "dummy_signature_handler" }
            let(:workflow_manifest) { Decidim::Initiatives::Signatures.find_workflow_manifest(workflow_name) }
            let(:authorization_handler_name) { workflow_manifest.authorization_handler_form }
            let(:handler_name) { "dummy_authorization_handler" }
            let(:unique_id) { "test_digest" }
            let(:metadata) do
              {
                test: "dummy",
                scope_id: initiative.scoped_type.scope.id
              }
            end
            let!(:authorization_handler) { authorization_handler_name.constantize.new }

            before do
              allow(authorization_handler).to receive(:unique_id).and_return(unique_id)
              allow(authorization_handler).to receive(:metadata).and_return(metadata)
              initiative.type.update(document_number_authorization_handler: workflow_name)
            end

            context "when current_user have an an authorization for the handler" do
              let!(:authorization) { create(:authorization, granted_at:, name: authorization_handler.handler_name, unique_id: authorization_unique_id, metadata: authorization_metadata, user: current_user) }
              let(:authorization_unique_id) { unique_id }
              let(:authorization_metadata) { metadata }
              let(:granted_at) { 1.minute.ago }

              context "when authorization unique_id and metadata are coincident with handler" do
                it "broadcasts ok" do
                  expect { command_with_personal_data.call }.to broadcast :ok
                end

                it "stores encrypted user personal data in vote" do
                  command_with_personal_data.call
                  vote = InitiativesVote.last
                  expect(vote.encrypted_metadata).to be_present
                  expect(vote.decrypted_metadata).to eq personal_data_params.except(:scope_id)
                  expect(vote.scope).to eq initiative.scope
                end
              end

              context "when authorization is not fully granted" do
                let(:granted_at) { nil }

                context "and the workflow saves authorizations" do
                  it "renews the authorization" do
                    expect { command_with_personal_data.call }.to broadcast :ok
                  end
                end

                context "and the workflow does not save the authorization" do
                  before do
                    allow(workflow_manifest).to receive(:save_authorizations).and_return(false)
                  end

                  it "does not renew the authorization and broadcasts invalid" do
                    expect { command_with_personal_data.call }.to broadcast :invalid
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
