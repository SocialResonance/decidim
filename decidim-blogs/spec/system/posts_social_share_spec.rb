# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/social_share_examples"

describe "Social shares" do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, hero_image:, organization:) }
  let(:hero_image) { Decidim::Dev.test_file("city2.jpeg", "image/jpeg") }
  let(:component) { create(:post_component, participatory_space: participatory_process) }
  let(:post) { create(:post, component:, body:) }
  let(:content_block) { create(:content_block, organization:, manifest_name: :hero, scope_name: :homepage) }
  let!(:attachment) { create(:attachment, :with_image, attached_to: post, file: attachment_file) }
  let(:body) { { en: "Description <p><img src=\"#{description_image_path}\"></p>" } }
  let!(:attachment_file) { Decidim::Dev.test_file("city3.jpeg", "image/jpeg") }
  let(:description_image_path) { Rails.application.routes.url_helpers.rails_blob_path(description_image, only_path: true) }
  let(:description_image) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Decidim::Dev.asset("city.jpeg")),
      filename: "description_image.jpg",
      content_type: "image/jpeg"
    )
  end
  let(:block_attachment_file) { Decidim::Dev.test_file("icon.png", "image/png") }
  let(:resource) { post }

  before do
    if content_block
      content_block.images_container.background_image = block_attachment_file
      content_block.save!
    end
    switch_to_host(organization.host)
  end

  it_behaves_like "a social share meta tag", "city3.jpeg"
  it_behaves_like "a social share widget"
  it_behaves_like "a social share via QR code" do
    let(:card_image) { "city3.jpeg" }
  end

  context "when no attachment images" do
    let!(:attachment) { nil }

    it_behaves_like "a social share meta tag", "description_image.jpg"
  end

  context "when no attachments nor description images" do
    let(:attachment) { nil }
    let(:description_image_path) { "" }

    it_behaves_like "a social share meta tag", "city2.jpeg"
  end

  context "when listing all posts" do
    let(:resource) { main_component_path(component) }

    it_behaves_like "a social share meta tag", "city2.jpeg"
  end
end
