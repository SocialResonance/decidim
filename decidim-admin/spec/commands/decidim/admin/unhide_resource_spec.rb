# frozen_string_literal: true

require "spec_helper"

module Decidim::Admin
  describe UnhideResource do
    let(:reportable) { create(:dummy_resource) }
    let(:moderation) { create(:moderation, reportable:, report_count: 1, hidden_at: Time.current) }
    let!(:report) { create(:report, moderation:) }
    let(:current_user) { create(:user, organization: reportable.participatory_space.organization) }
    let(:command) { described_class.new(reportable, current_user) }

    context "when everything is ok" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "unhides the resource" do
        command.call
        expect(reportable.reload).not_to be_hidden
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:perform_action!)
          .with("unhide", moderation, current_user, extra: { reportable_type: "Decidim::Dev::DummyResource" })
          .and_call_original

        expect { command.call }.to change(Decidim::ActionLog, :count)

        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
        expect(action_log.version.event).to eq "update"
      end
    end

    context "when the resource is not hidden" do
      let(:moderation) { create(:moderation, reportable:, report_count: 1, hidden_at: nil) }

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end
    end

    context "when the resource is not reported" do
      let(:moderation) { nil }
      let!(:report) { nil }

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end
    end

    context "when the resource parent is hidden" do
      let!(:comment) { create(:comment, commentable: reportable, author: current_user) }
      let!(:comment_moderation) { create(:moderation, reportable: comment, report_count: 1, hidden_at: Time.current) }

      let(:command) { described_class.new(comment, current_user) }

      it "broadcasts parent_invalid" do
        expect { command.call }.to broadcast(:parent_invalid)
      end

      it "does not unhide the resource" do
        command.call
        expect(comment.reload).to be_hidden
      end
    end

    context "when the resource parent is not hidden" do
      let(:moderation) { create(:moderation, reportable:, report_count: 1, hidden_at: nil) }
      let!(:comment) { create(:comment, commentable: reportable, author: current_user) }
      let!(:comment_moderation) { create(:moderation, reportable: comment, report_count: 1, hidden_at: Time.current) }

      let(:command) { described_class.new(comment, current_user) }

      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "unhides the resource" do
        command.call
        expect(comment.reload).not_to be_hidden
      end
    end
  end
end
