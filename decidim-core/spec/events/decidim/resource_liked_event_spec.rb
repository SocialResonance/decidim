# frozen_string_literal: true

require "spec_helper"

describe Decidim::ResourceLikedEvent do
  let(:resource) { create(:dummy_resource, title: { en: "My super dummy resource" }) }
  let(:resource_type) { "Dummy resource" }
  let(:resource_text) { resource.body }

  it_behaves_like "resource liked event"
end
