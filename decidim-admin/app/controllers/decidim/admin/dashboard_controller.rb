# frozen_string_literal: true

module Decidim
  module Admin
    # Controller that shows a simple dashboard.
    #
    class DashboardController < Decidim::Admin::ApplicationController
      helper_method :latest_action_logs
      helper_method :users_counter
      helper_method :count_pending_moderations

      def show
        enforce_permission_to :read, :admin_dashboard
      end

      private

      def count_pending_moderations
        @count_pending_moderations ||= Decidim::Admin::ModerationStats.new(current_user).count_pending_moderations
      end

      def latest_action_logs
        @latest_action_logs ||= Decidim::ActionLog
                                .where(organization: current_organization)
                                .includes(:participatory_space, :user, :resource, :component, :version)
                                .for_admin
                                .order(created_at: :desc)
                                .first(5)
      end

      def users_counter
        last_day = Time.zone.yesterday
        last_week = Time.zone.today.prev_week
        last_month = Time.zone.today.prev_month

        {
          total_admins_last_day: users_count(last_day, true),
          total_admins_last_week: users_count(last_week, true),
          total_admins_last_month: users_count(last_month, true),
          total_participants_last_day: users_count(last_day, false),
          total_participants_last_week: users_count(last_week, false),
          total_participants_last_month: users_count(last_month, false)
        }
      end

      def users_count(date, admin)
        @users_count = Decidim::Admin::ActiveUsersCounter.new(
          organization: current_organization,
          date:,
          admin:
        ).query.count
      end
    end
  end
end
