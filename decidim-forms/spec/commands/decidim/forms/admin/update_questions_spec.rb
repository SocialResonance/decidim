# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Forms
    module Admin
      describe UpdateQuestions do
        let(:current_organization) { create(:organization) }
        let(:participatory_process) { create(:participatory_process, organization: current_organization) }
        let(:questionnaire) { create(:questionnaire, questionnaire_for: participatory_process) }
        let(:user) { create(:user, organization: current_organization) }
        let(:published_at) { nil }
        let(:form_params) do
          {
            "questions" => {
              "0" => {
                "body" => {
                  "en" => "First question",
                  "ca" => "Primera pregunta",
                  "es" => "Primera pregunta"
                },
                "position" => "0",
                "question_type" => "short_response",
                "max_characters" => "0",
                "response_options" => {}
              },
              "1" => {
                "body" => {
                  "en" => "Second question",
                  "ca" => "Segona pregunta",
                  "es" => "Segunda pregunta"
                },
                "description" => { "en" => "Description" },
                "position" => "1",
                "mandatory" => "1",
                "question_type" => "long_response",
                "max_characters" => "100",
                "response_options" => {}
              },
              "2" => {
                "body" => {
                  "en" => "Third question",
                  "ca" => "Tercera pregunta",
                  "es" => "Tercera pregunta"
                },
                "position" => "2",
                "question_type" => "single_option",
                "max_characters" => "0",
                "response_options" => {
                  "0" => {
                    "body" => {
                      "en" => "First response",
                      "ca" => "Primera resposta",
                      "es" => "Primera respuesta"
                    },
                    "free_text" => "0"
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second response",
                      "ca" => "Segona resposta",
                      "es" => "Segunda respuesta"
                    }
                  }
                }
              },
              "3" => {
                "body" => {
                  "en" => "Fourth question",
                  "ca" => "Quarta pregunta",
                  "es" => "Cuarta pregunta"
                },
                "position" => "3",
                "question_type" => "multiple_option",
                "max_choices" => "2",
                "response_options" => {
                  "0" => {
                    "body" => {
                      "en" => "First response",
                      "ca" => "Primera resposta",
                      "es" => "Primera respuesta"
                    },
                    "free_text" => "1"
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second response",
                      "ca" => "Segona resposta",
                      "es" => "Segunda respuesta"
                    }
                  }
                }
              },
              "4" => {
                "body" => {
                  "en" => "Fifth question",
                  "ca" => "Cinquena pregunta",
                  "es" => "Quinta pregunta"
                },
                "position" => "4",
                "question_type" => "matrix_single",
                "response_options" => {
                  "0" => {
                    "body" => {
                      "en" => "First response",
                      "ca" => "Primera resposta",
                      "es" => "Primera respuesta"
                    },
                    "free_text" => "1"
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second response",
                      "ca" => "Segona resposta",
                      "es" => "Segunda respuesta"
                    }
                  }
                },
                "matrix_rows" => {
                  "0" => {
                    "body" => {
                      "en" => "First row",
                      "ca" => "Primera fila",
                      "es" => "Primera fila"
                    }
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second row",
                      "ca" => "Segona fila",
                      "es" => "Segunda fila"
                    }
                  }
                }
              },
              "5" => {
                "body" => {
                  "en" => "Sixth question",
                  "ca" => "Sisena pregunta",
                  "es" => "Sexta pregunta"
                },
                "position" => "5",
                "question_type" => "matrix_multiple",
                "max_choices" => "2",
                "response_options" => {
                  "0" => {
                    "body" => {
                      "en" => "First response",
                      "ca" => "Primera resposta",
                      "es" => "Primera respuesta"
                    },
                    "free_text" => "1"
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second response",
                      "ca" => "Segona resposta",
                      "es" => "Segunda respuesta"
                    }
                  }
                },
                "matrix_rows" => {
                  "0" => {
                    "body" => {
                      "en" => "First row",
                      "ca" => "Primera fila",
                      "es" => "Primera fila"
                    }
                  },
                  "1" => {
                    "body" => {
                      "en" => "Second row",
                      "ca" => "Segona fila",
                      "es" => "Segunda fila"
                    }
                  }
                }
              }
            },
            "published_at" => published_at
          }
        end
        let(:form) do
          QuestionsForm.from_params(
            questions: form_params
          ).with_context(
            current_organization:,
            current_user: user
          )
        end
        let(:command) { described_class.new(form, questionnaire) }

        describe "when the form is invalid" do
          before do
            allow(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "does not update the questionnaire" do
            expect(questionnaire).not_to receive(:update!)
            command.call
          end
        end

        describe "when the form is valid" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "updates the questions" do
            command.call
            questionnaire.reload

            expect(questionnaire.questions.length).to eq(6)

            questionnaire.questions.each_with_index do |question, idx|
              expect(question.body["en"]).to eq(form_params["questions"][idx.to_s]["body"]["en"])
            end

            expect(questionnaire.questions[1]).to be_mandatory
            expect(questionnaire.questions[1].description["en"]).to eq(form_params["questions"]["1"]["description"]["en"])
            expect(questionnaire.questions[1].question_type).to eq("long_response")
            expect(questionnaire.questions[1].max_characters).to eq(100)
            expect(questionnaire.questions[2].response_options[1]["body"]["en"]).to eq(form_params["questions"]["2"]["response_options"]["1"]["body"]["en"])

            expect(questionnaire.questions[2].question_type).to eq("single_option")
            expect(questionnaire.questions[2].max_choices).to be_nil
            expect(questionnaire.questions[2].max_characters).to eq(0)

            expect(questionnaire.questions[3].question_type).to eq("multiple_option")
            expect(questionnaire.questions[2].response_options[0].free_text).to be(false)
            expect(questionnaire.questions[2].max_choices).to be_nil

            expect(questionnaire.questions[3].question_type).to eq("multiple_option")
            expect(questionnaire.questions[3].response_options[0].free_text).to be(true)
            expect(questionnaire.questions[3].max_choices).to eq(2)

            expect(questionnaire.questions[4].question_type).to eq("matrix_single")
            expect(questionnaire.questions[4].response_options[0].free_text).to be(true)
            2.times do |idx|
              expect(questionnaire.questions[4].matrix_rows[idx].body["en"]).to eq(form_params["questions"]["4"]["matrix_rows"][idx.to_s]["body"]["en"])
              expect(questionnaire.questions[4].matrix_rows[idx].position).to eq(idx)
            end

            expect(questionnaire.questions[5].question_type).to eq("matrix_multiple")
            expect(questionnaire.questions[5].response_options[0].free_text).to be(true)
            expect(questionnaire.questions[5].matrix_rows[0].body["en"]).to eq(form_params["questions"]["5"]["matrix_rows"]["0"]["body"]["en"])
          end

          it "traces the action", versioning: true do
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with("update", questionnaire, user)
              .and_call_original

            expect { command.call }.to change(Decidim::ActionLog, :count)
            action_log = Decidim::ActionLog.last
            expect(action_log.action).to eq("update")
            expect(action_log.version).to be_present
          end
        end

        describe "when the questionnaire has an existing question" do
          let!(:question) { create(:questionnaire_question, questionnaire:) }

          context "and the question should be removed" do
            let(:form_params) do
              {
                "questions" => [
                  {
                    "id" => question.id,
                    "body" => question.body,
                    "position" => 0,
                    "question_type" => "short_response",
                    "deleted" => "true"
                  }
                ]
              }
            end

            it "deletes the questionnaire question" do
              command.call
              questionnaire.reload

              expect(questionnaire.questions.length).to eq(0)
            end
          end
        end

        describe "when the questionnaire has existing questions" do
          let!(:questions) { 0.upto(3).to_a.map { |x| create(:questionnaire_question, questionnaire:, position: x) } }
          let!(:question_2_response_options) { create_list(:response_option, 3, question: questions.second) }

          context "and display conditions are to be created" do
            let(:form_params) do
              {
                "questions" => {
                  "1" => {
                    "id" => questions[0].id,
                    "body" => questions[0].body,
                    "position" => 0,
                    "question_type" => "short_response"
                  },
                  "2" => {
                    "id" => questions[1].id,
                    "body" => questions[1].body,
                    "position" => 1,
                    "question_type" => "single_option",
                    "response_options" => question_2_response_options.to_h do |response_option|
                      [response_option.id.to_s, { "id" => response_option.id, "body" => response_option.body, "free_text" => response_option.free_text, "deleted" => false }]
                    end
                  },
                  "3" => {
                    "id" => questions[2].id,
                    "body" => questions[2].body,
                    "position" => 2,
                    "question_type" => "short_response",
                    "deleted" => "false",
                    "display_conditions" => {
                      "1" => {
                        "decidim_condition_question_id" => questions[0].id,
                        "decidim_question_id" => questions[2].id,
                        "condition_type" => "responded"
                      },
                      "2" => {
                        "decidim_condition_question_id" => questions[1].id,
                        "decidim_question_id" => questions[2].id,
                        "condition_type" => "equal",
                        "decidim_response_option_id" => question_2_response_options.first.id
                      }
                    }
                  }
                }
              }
            end

            it "saves the questionnaire" do
              expect { command.call }.to broadcast(:ok)
              questionnaire.reload

              expect(questionnaire.questions[2].display_conditions).not_to be_empty
              expect(questionnaire.questions[2].display_conditions.first.condition_type).to eq("responded")
              expect(questionnaire.questions[2].display_conditions.second.condition_type).to eq("equal")
              expect(questionnaire.questions[2].display_conditions.second.decidim_response_option_id).to eq(question_2_response_options.first.id)
            end
          end
        end
      end
    end
  end
end
