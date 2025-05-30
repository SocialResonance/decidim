# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Forms
    describe Response do
      subject { response }

      let(:organization) { create(:organization) }
      let(:user) { create(:user, organization:) }
      let(:participatory_process) { create(:participatory_process, organization:) }
      let(:questionnaire) { create(:questionnaire, questionnaire_for: participatory_process) }
      let(:question) { create(:questionnaire_question, questionnaire:) }
      let(:response) { create(:response, questionnaire:, question:, user:) }

      it { is_expected.to be_valid }

      it "has an association of questionnaire" do
        expect(subject.questionnaire).to eq(questionnaire)
      end

      it "has an association of question" do
        expect(subject.question).to eq(question)
      end

      it "has an association of user" do
        expect(subject.user).to eq(user)
      end

      context "when the user does not belong to the same organization" do
        it "is not valid" do
          subject.user = create(:user)
          expect(subject).not_to be_valid
        end
      end

      context "when question does not belong to the questionnaire" do
        it "is not valid" do
          subject.question = create(:questionnaire_question)
          expect(subject).not_to be_valid
        end
      end
    end
  end
end
