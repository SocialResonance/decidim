# frozen_string_literal: true

require "spec_helper"

describe Decidim::Meetings::UpcomingMeetingEvent do
  let(:resource) { create(:meeting, title: { en: "It is my meeting" }) }
  let(:resource_title) { translated(resource.title) }
  let(:event_name) { "decidim.events.meetings.upcoming_meeting" }

  include_context "when a simple event"
  it_behaves_like "a simple event"
  it_behaves_like "a translated meeting event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("The \"#{resource_title}\" meeting will start in less than 48h.")
    end
  end

  describe "default_email_intro" do
    context "when custom message is unset" do
      it "is generated correctly" do
        resource.reminder_message_custom_content = nil
        expect(subject.email_intro).to eq("The \"#{resource_title}\" meeting will start in less than 48h.")
      end
    end

    context "when custom message is set" do
      it "is generated correctly" do
        resource.reminder_message_custom_content = { "en" => "My custom message that states \"{{meeting_title}}\" starts in {{before_hours}} hours" }
        expect(subject.email_intro).to eq("My custom message that states \"#{resource_title}\" starts in 48 hours")
      end
    end

    context "when custom message has a customized time interval" do
      it "is generated correctly" do
        resource.send_reminders_before_hours = 2
        resource.reminder_message_custom_content = nil
        expect(subject.email_intro).to eq("The \"#{resource_title}\" meeting will start in less than 2h.")
      end
    end
  end

  describe "resource_text" do
    it "returns the meeting description" do
      expect(subject.resource_text).to eq translated(resource.description)
    end
  end

  describe "custom reminder message" do
    let(:resource) do
      create(:meeting,
             title: { en: "Custom Meeting" },
             reminder_enabled: true,
             send_reminders_before_hours: 25,
             reminder_message_custom_content: { en: "Reminder for the {{meeting_title}} meeting. Meeting will start in {{before_hours}}h" })
    end

    it "interpolates the meeting title into the custom message" do
      expect(subject.email_intro).to eq "Reminder for the Custom Meeting meeting. Meeting will start in 25h"
    end

    it "generates the email subject with correct hours" do
      expect(subject.email_subject).to eq("The \"#{resource_title}\" meeting will start in less than 25h.")
    end
  end
end
