# frozen_string_literal: true

require "spec_helper"

describe "Private Space Respond a survey" do
  let(:manifest_name) { "surveys" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }

  let(:title) do
    {
      "en" => "Survey's title",
      "ca" => "Títol de l'enquesta'",
      "es" => "Título de la encuesta"
    }
  end
  let(:description) do
    {
      "en" => "<p>Survey's content</p>",
      "ca" => "<p>Contingut de l'enquesta</p>",
      "es" => "<p>Contenido de la encuesta</p>"
    }
  end

  let!(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization:) }
  let!(:another_user) { create(:user, :confirmed, organization:) }

  let!(:participatory_space_private_user) { create(:participatory_space_private_user, user: another_user, privatable_to: participatory_space_private) }

  let!(:questionnaire) { create(:questionnaire, title:, description:) }
  let!(:survey) { create(:survey, :published, :allow_responses, component:, questionnaire:) }
  let!(:question) { create(:questionnaire_question, questionnaire:, position: 0) }
  let!(:question_conditioned) { create(:questionnaire_question, :conditioned, questionnaire:, position: 1) }

  let!(:participatory_space) { participatory_space_private }

  let!(:component) { create(:component, manifest:, participatory_space:) }

  before do
    switch_to_host(organization.host)
  end

  def visit_component
    page.visit main_component_path(component)
  end

  context "when space is private and transparent" do
    let!(:participatory_space_private) { create(:assembly, :published, organization:, private_space: true, is_transparent: true) }

    context "when the user is not logged in" do
      it "does not allow responding the survey" do
        visit_component
        click_on translated_attribute(questionnaire.title)

        expect(page).to have_i18n_content(questionnaire.title)
        expect(page).to have_i18n_content(questionnaire.description)

        expect(page).to have_no_css(".form.response-questionnaire")

        within "[data-question-readonly]" do
          expect(page).to have_i18n_content(question.body)
          expect(page).not_to have_i18n_content(question_conditioned.body)
        end
      end
    end

    context "when the user is logged in" do
      context "and is private user space" do
        before do
          login_as another_user, scope: :user
        end

        it "allows responding the survey" do
          visit_component
          click_on translated_attribute(questionnaire.title)

          expect(page).to have_i18n_content(questionnaire.title)
          expect(page).to have_i18n_content(questionnaire.description)

          fill_in question.body["en"], with: "My first response"

          check "questionnaire_tos_agreement"

          accept_confirm { click_on "Submit" }

          within ".success.flash" do
            expect(page).to have_content("successfully")
          end

          expect(page).to have_content("You have already responded this form.")
          expect(page).to have_no_i18n_content(question.body)
        end
      end

      context "and is not private user space" do
        before do
          login_as user, scope: :user
        end

        it "not allows responding the survey" do
          visit_component
          click_on translated_attribute(questionnaire.title)

          expect(page).to have_i18n_content(questionnaire.title)
          expect(page).to have_i18n_content(questionnaire.description)
          expect(page).to have_content "The form is available only for private users"
          expect(page).to have_content "Form closed"

          expect(page).to have_css(".button[disabled]")
        end
      end
    end
  end

  context "when the spaces is private and not transparent" do
    let!(:participatory_space_private) { create(:assembly, :published, organization:, private_space: true, is_transparent: false) }

    context "when the user is not logged in" do
      let(:target_path) { main_component_path(component) }

      before do
        visit target_path
      end

      it "disallows the access" do
        expect(page).to have_content("You are not authorized to perform this action")
      end
    end

    context "when the user is logged in" do
      context "and is private user space" do
        before do
          login_as another_user, scope: :user
        end

        it "allows responding the survey" do
          visit_component
          choose "All"

          expect(page).to have_i18n_content(questionnaire.title)
          expect(page).to have_i18n_content(questionnaire.description)

          click_on translated_attribute(questionnaire.title)

          fill_in question.body["en"], with: "My first response"

          check "questionnaire_tos_agreement"

          accept_confirm { click_on "Submit" }

          within ".success.flash" do
            expect(page).to have_content("successfully")
          end

          expect(page).to have_content("You have already responded this form.")
          expect(page).to have_no_i18n_content(question.body)
        end
      end

      context "and is not private user space" do
        let(:target_path) { main_component_path(component) }

        before do
          login_as user, scope: :user
          visit target_path
        end

        it "disallows the access" do
          expect(page).to have_content("You are not authorized to perform this action")
        end
      end
    end
  end
end
