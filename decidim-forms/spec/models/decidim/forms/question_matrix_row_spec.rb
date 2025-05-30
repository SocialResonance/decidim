# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Forms
    describe QuestionMatrixRow do
      subject { question_matrix_row }

      let(:questionnaire) { create(:questionnaire) }
      let(:question_type) { "matrix_single" }
      let(:question) { create(:questionnaire_question, questionnaire:, question_type:) }
      let(:question_matrix_row) { build(:question_matrix_row, question:) }

      it { is_expected.to be_valid }

      it "has an association of question" do
        expect(subject.question).to eq(question)
      end

      it "has an association of response_options" do
        subject.response_options << create(:response_option, question:)
        subject.response_options << create(:response_option, question:)
        expect(subject.response_options.count).to eq(2)
      end

      describe "#mandatory" do
        it "is delegated to question" do
          expect(subject.mandatory).to eq(question.mandatory)
        end
      end
    end
  end
end
