# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test"

module Decidim
  module Core
    describe DateType, type: :graphql do
      include_context "with a graphql scalar class type"
      let(:model) { Time.new(2018, 2, 22, 9, 47, 0, "+01:00") }

      it "returns the formatted date" do
        expect(response).to eq("2018-02-22")
      end
    end
  end
end
