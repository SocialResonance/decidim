# frozen_string_literal: true

require "spec_helper"

describe Decidim::EventsManager do
  describe "#publish" do
    let(:event) { "my.event" }
    let(:event_class) { Decidim::Events::BaseEvent }
    let(:resource) { double }
    let(:extra) { double }
    let(:organization) { create(:organization) }
    let(:followers) { create_list(:user, 3, organization:) }
    let(:affected_users) { create_list(:user, 3, organization:) }
    let(:force_send) { true }

    it "delegates the params to ActiveSupport::Notifications" do
      expect(ActiveSupport::Notifications)
        .to receive(:publish)
        .with(
          event,
          event_class: "Decidim::Events::BaseEvent",
          resource:,
          followers:,
          affected_users:,
          force_send:,
          extra:
        )

      described_class.publish(
        event:,
        event_class:,
        resource:,
        followers:,
        affected_users:,
        force_send:,
        extra:
      )
    end

    context "when there are invalid values as affected_users" do
      let(:affected_users) { followers + followers + [nil] }

      it "sanitizes the recipients" do
        expect(ActiveSupport::Notifications)
          .to receive(:publish)
          .with(event, hash_including(affected_users: followers))

        described_class.publish(
          event:,
          event_class:,
          resource:,
          followers:,
          affected_users:,
          extra:
        )
      end
    end

    context "when there are invalid values as followers" do
      let(:followers) { affected_users + affected_users + [nil] }

      it "sanitizes the recipients" do
        expect(ActiveSupport::Notifications)
          .to receive(:publish)
          .with(event, hash_including(followers: affected_users))

        described_class.publish(
          event:,
          event_class:,
          resource:,
          followers:,
          affected_users:,
          extra:
        )
      end
    end
  end

  describe "#subscribe" do
    let(:event) { "my.event" }
    let(:block) { proc { raise "Hello world" } }

    it "delegates the params to ActiveSupport::Notifications" do
      allow(ActiveSupport::Notifications)
        .to receive(:subscribe)
        .with(event, &block)

      expect { described_class.subscribe(event, &block) }.to raise_error("Hello world")
    end
  end
end
