# frozen_string_literal: true

module Decidim
  module Meetings
    # Custom helpers used in meetings views
    module MeetingsHelper
      include Decidim::ApplicationHelper
      include Decidim::Meetings::ApplicationHelper
      include Decidim::TranslationsHelper
      include Decidim::ResourceHelper
      include Decidim::LikeableHelper

      # Public: truncates the meeting description
      #
      # meeting - a Decidim::Meeting instance
      # max_length - a number to limit the length of the description
      #
      # Returns the meeting's description truncated.
      def meeting_description(meeting, max_length = 120)
        link = resource_locator(meeting).path
        description = CGI.unescapeHTML present(meeting).description
        tail = "... #{link_to(t("read_more", scope: "decidim.meetings"), link)}".html_safe
        CGI.unescapeHTML html_truncate(description, max_length:, tail:)
      end

      def waitlist_status_block(registration)
        return unless registration.waiting_list?

        render layout: "decidim/meetings/layouts/aside_block", locals: { emoji: "ticket-line" } do
          content_tag(:div) do
            safe_join([
                        content_tag(:h3, t("waitlist.status", scope: "decidim.meetings.meetings.show"), class: "meeting__aside-block__title"),
                        content_tag(:p, t("waitlist.description", scope: "decidim.meetings.meetings.show"), class: "text-sm")
                      ])
          end
        end
      end

      # Public: The css class applied based on the meeting type to
      #         the css class.
      #
      # type - The String type of the meeting.
      #
      # Returns a String.
      def meeting_type_badge_css_class(type)
        case type
        when "withdraw"
          "alert"
        when "private", "transparent"
          "reverse"
        end
      end

      # Public: This method is used to calculate the start and end time
      #         of each agenda item passed
      #
      # agenda_items - an Active record of agenda items
      # meeting - the meeting of the agenda, to know the start and end time
      # start_time_parent - used to pass the start time of parent agenda item
      #
      # Returns an Array.
      def calculate_start_and_end_time_of_agenda_items(agenda_items, meeting, start_time_parent = nil)
        array = []

        agenda_items.each_with_index do |agenda_item, index|
          hash = {
            agenda_item_id: agenda_item.id,
            start_time: nil,
            end_time: nil
          }
          if index.zero?
            start = if agenda_item.parent?
                      meeting.start_time
                    else
                      start_time_parent
                    end

            hash[:start_time] = start
          else
            hash[:start_time] = array[index - 1][:end_time]
          end

          hash[:end_time] = hash[:start_time] + agenda_item.duration.minutes

          array.push(hash)
        end

        array
      end

      # Public: This method is used to build the html for show start
      # and end time of each agenda item
      #
      # agenda_item_id - an id of agenda item
      # agenda_items_times - is a hash with the two times
      #
      # Returns an HMTL.
      def display_duration_agenda_items(agenda_item_id, index, agenda_items_times)
        html = ""
        if agenda_item_id == agenda_items_times[index][:agenda_item_id]
          html += "[#{agenda_items_times[index][:start_time].strftime("%H:%M")} - #{agenda_items_times[index][:end_time].strftime("%H:%M")}]"
        end
        html.html_safe
      end

      # Public: Registration code generic help text.
      #
      # Returns a String.
      def registration_code_help_text
        t("registration_code_help_text", scope: "decidim.meetings.meetings.show")
      end

      # Public: Registration validation state as text.
      #
      # registration - The registration that holds the validation code.
      #
      # Returns a String.
      def validation_state_for(registration)
        if registration.validated?
          t("validated", scope: "decidim.meetings.meetings.show.registration_state")
        else
          t("validation_pending", scope: "decidim.meetings.meetings.show.registration_state")
        end
      end

      def author_presenter_for(author)
        if author.is_a?(Decidim::Organization)
          Decidim::Meetings::OfficialAuthorPresenter.new
        else
          present(author)
        end
      end

      # Public: URL to create an event in Google Calendars based on meeting
      # data.
      #
      # meeting - a Decidim::Meeting instance.
      #
      # Returns a String.
      def google_calendar_event_url(meeting)
        meeting_url = resource_locator(meeting).url
        meeting = present(meeting)
        params = {
          text: meeting.title,
          dates: meeting.dates_param,
          details: I18n.t(
            "decidim.meetings.meetings.calendar_modal.full_details_html",
            link: link_to(meeting_url, meeting_url)
          )
        }
        base_url = "https://calendar.google.com/calendar/u/0/r/eventedit"
        "#{base_url}?#{params.to_param}"
      end

      def render_schema_org_event_meeting(meeting)
        exported_meeting = Decidim::Exporters::JSON.new([meeting], Decidim::Meetings::SchemaOrgEventMeetingSerializer).export.read
        JSON.pretty_generate(JSON.parse(exported_meeting).first)
      end
    end
  end
end
