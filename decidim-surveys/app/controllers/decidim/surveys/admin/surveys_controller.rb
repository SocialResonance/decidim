# frozen_string_literal: true

module Decidim
  module Surveys
    module Admin
      # This controller allows to index, create, update, destroy, publish and unpublish a Survey.
      class SurveysController < Admin::ApplicationController
        include Decidim::Surveys::Admin::Filterable

        helper_method :surveys

        def index; end

        def new
          enforce_permission_to(:create, :questionnaire)

          @form = form(Admin::SurveyForm).instance
        end

        def create
          enforce_permission_to(:create, :questionnaire)

          @form = form(Admin::SurveyForm).from_params(params)
          Decidim::Surveys::Admin::CreateSurvey.call(current_component, @form) do
            on(:ok) do |survey|
              flash[:notice] = I18n.t("create.success", scope: "decidim.surveys.admin.surveys")
              redirect_to edit_survey_path(survey)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("create.invalid", scope: "decidim.surveys.admin.surveys")
              render action: "new"
            end
          end
        end

        def edit
          enforce_permission_to(:update, :questionnaire, questionnaire: survey)
          @form = form(Admin::SurveyForm).from_model(survey)
        end

        def update
          enforce_permission_to(:update, :questionnaire, questionnaire: survey)
          @form = form(Admin::SurveyForm).from_params(params)

          Admin::UpdateSurvey.call(@form, survey, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("update.success", scope: "decidim.surveys.admin.surveys")
              redirect_to edit_survey_path(survey)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("update.invalid", scope: "decidim.surveys.admin.surveys")
              render action: "edit"
            end
          end
        end

        def publish
          enforce_permission_to(:update, :questionnaire, questionnaire: survey)
          Decidim::Surveys::Admin::PublishSurvey.call(survey, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("publish.success", scope: "decidim.surveys.admin.surveys")
              redirect_to surveys_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("publish.invalid", scope: "decidim.surveys.admin.surveys")
              render action: "index"
            end
          end
        end

        def unpublish
          enforce_permission_to(:update, :questionnaire, questionnaire: survey)
          Decidim::Surveys::Admin::UnpublishSurvey.call(survey, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("unpublish.success", scope: "decidim.surveys.admin.surveys")
              redirect_to surveys_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("unpublish.invalid", scope: "decidim.surveys.admin.surveys")
              render action: "index"
            end
          end
        end

        def destroy
          enforce_permission_to(:destroy, :questionnaire, questionnaire: survey)
          Decidim::Commands::DestroyResource.call(survey, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("destroy.success", scope: "decidim.surveys.admin.surveys")

              redirect_to surveys_path
            end
          end
        end

        private

        def surveys
          @surveys ||= filtered_collection
        end

        def survey
          @survey ||= collection.find(params[:id])
        end

        def collection
          @collection ||= Decidim::Surveys::Survey.where(component: current_component)
        end
      end
    end
  end
end
