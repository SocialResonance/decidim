# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test"

module Decidim
  module Core
    describe DecidimType do
      subject { described_class }

      include_context "with a graphql class type"

      let(:model) do
        Decidim
      end

      describe "version" do
        let(:query) { "{ version }" }

        it "returns the version" do
          expect(response).to eq("version" => nil)
        end

        context "when disclosing system version is enabled" do
          before do
            allow(Decidim::Api).to receive(:disclose_system_version).and_return(true)
          end

          it "returns the version" do
            expect(response).to eq("version" => Decidim.version)
          end
        end
      end

      describe "applicationName" do
        let(:query) { "{ applicationName }" }

        it "returns the application's name" do
          expect(response).to eq("applicationName" => Decidim.application_name)
        end
      end
    end
  end
end
