# frozen_string_literal: true

require "decidim/components/namer"
require "decidim/core/test/factories"

FactoryBot.define do
  factory :factory_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :factory).i18n_name }
    manifest_name :factory
    participatory_space { create(:participatory_process, :with_steps) }
  end

  # Add engine factories here
end
