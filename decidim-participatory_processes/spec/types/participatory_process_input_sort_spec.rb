# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test"

module Decidim
  module ParticipatoryProcesses
    describe ParticipatoryProcessInputSort, type: :graphql do
      include_context "with a graphql class type"
      let(:type_class) { Decidim::Api::QueryType }
      let!(:models) { create_list(:participatory_process, 3, :published, organization: current_organization) }

      context "when sorting by participatory process id" do
        include_examples "collection has input sort", "participatoryProcesses", "id"
      end

      context "when sorting by participatory process published_at" do
        include_examples "collection has input sort", "participatoryProcesses", "publishedAt"
      end

      context "when sorting by participatory process start_date" do
        before do
          models.each_with_index do |model, index|
            model.start_date = index.day.ago
            model.save!
          end
        end

        include_examples "collection has input sort", "participatoryProcesses", "startDate"
      end
    end
  end
end
