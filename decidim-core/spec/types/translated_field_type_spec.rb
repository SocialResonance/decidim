# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test"

module Decidim
  module Core
    describe TranslatedFieldType do
      include_context "with a graphql class type"

      shared_context "with machine translations" do
        let(:model) do
          {
            ca: "Hola",
            en: "Hello",
            es: "",
            machine_translations: {
              es: "Ey"
            }
          }
        end
      end

      let(:model) do
        {
          ca: "Hola",
          en: "Hello"
        }
      end

      describe "locales" do
        let(:query) { "{ locales }" }

        it "returns the available locales" do
          expect(response["locales"]).to include("en", "ca")
        end

        context "when there are machine translations" do
          include_context "with machine translations"

          it "returns all available locales with no duplicates" do
            expect(response["locales"]).to include("en", "ca", "es")
          end
        end
      end

      describe "translations" do
        context "when locales are not provided" do
          let(:query) { "{ translations { locale text }}" }

          it "returns all the translations" do
            translations = response["translations"]
            expect(translations.length).to eq(2)
            expect(translations).to include("locale" => "ca", "text" => "Hola")
            expect(translations).to include("locale" => "en", "text" => "Hello")
          end

          context "when there are machine translations" do
            include_context "with machine translations"

            let(:query) { "{ translations { locale text machineTranslated }}" }

            it "returns correct translations" do
              translations = response["translations"]
              expect(translations.length).to eq(3)
              expect(translations).to include("locale" => "ca", "text" => "Hola", "machineTranslated" => false)
              expect(translations).to include("locale" => "en", "text" => "Hello", "machineTranslated" => false)
              expect(translations).to include("locale" => "es", "text" => "Ey", "machineTranslated" => true)
            end

            context "with defined translation overriding machine translation" do
              let(:model) do
                {
                  ca: "Hola",
                  en: "Hello",
                  es: "Hola",
                  machine_translations: {
                    es: "Ey"
                  }
                }
              end

              it "returns correct translations" do
                translations = response["translations"]
                expect(translations.length).to eq(3)
                expect(translations).to include("locale" => "ca", "text" => "Hola", "machineTranslated" => false)
                expect(translations).to include("locale" => "en", "text" => "Hello", "machineTranslated" => false)
                expect(translations).to include("locale" => "es", "text" => "Hola", "machineTranslated" => false)
              end
            end
          end
        end

        context "when locales are provided" do
          let(:query) { '{ translations(locales: ["ca"]) { locale text }}' }

          it "returns the translations on the provided locales" do
            translations = response["translations"]
            expect(translations).to include("locale" => "ca", "text" => "Hola")
            expect(translations).not_to include("locale" => "en", "text" => "Hello")
          end
        end
      end

      describe "translation" do
        context "when the locale is found" do
          let(:query) { '{ translation(locale: "ca") }' }

          it "returns the translation for that language" do
            translation = response["translation"]
            expect(translation).to eq("Hola")
          end
        end

        context "when the locale is not found" do
          let(:query) { '{ translation(locale: "fake") }' }

          it "returns a null value" do
            translation = response["translation"]
            expect(translation).to be_nil
          end
        end
      end
    end
  end
end
