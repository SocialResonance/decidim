# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Accountability
    describe VersionsController, versioning: true do
      let(:resource) { create(:result) }

      it_behaves_like "versions controller"
    end
  end
end
