# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Search do
    # We cannot use the shared example "global search of participatory spaces",
    # as the Participatory Process Group is not Publicable (does not have a `published_at` column)
    let(:participatory_process_group) do
      create(
        :participatory_process_group,
        organization:,
        title: Decidim::Faker::Localized.name,
        description: description1
      )
    end
    let(:participatory_space) { participatory_process_group }
    let(:participatory_process_group2) do
      create(
        :participatory_process_group,
        organization:,
        title: Decidim::Faker::Localized.name,
        description: description2
      )
    end
    let(:participatory_space2) { participatory_process_group2 }
    let(:searchable_resource_attrs_mapper) do
      lambda { |space, locale|
        {
          "content_a" => I18n.transliterate(translated(space.title, locale:)),
          "content_d" => I18n.transliterate(translated(space.description, locale:))
        }
      }
    end

    include_context "when a resource is ready for global search"

    describe "Indexing of participatory_spaces" do
      context "when on create" do
        context "when participatory_spaces are created" do
          it "indexes a SearchableResource after ParticipatorySpace creation" do
            searchables = Decidim::SearchableResource.where(resource_type: participatory_space.class.name, resource_id: participatory_space.id)
            expect(searchables.first.content_a).to eq participatory_space.title["en"].to_s
          end
        end
      end

      context "when on update" do
        it "updates the associated SearchableResource ParticipatorySpace update" do
          searchable = Decidim::SearchableResource.find_by(resource_type: participatory_space.class.name, resource_id: participatory_space.id)
          created_at = searchable.created_at
          updated_title = { "en" => "Brand new title", "machine_translations" => {} }
          participatory_space.update(title: updated_title)

          participatory_space.save!
          searchable.reload

          organization.available_locales.each do |locale|
            searchable = Decidim::SearchableResource.find_by(resource_type: participatory_space.class.name, resource_id: participatory_space.id, locale:)
            expect(searchable.content_a).to eq updated_title[locale.to_s].to_s
            expect(searchable.updated_at).to be > created_at
          end
        end
      end

      context "when on destroy" do
        it "destroys the associated SearchableResource after ParticipatorySpace destroy" do
          participatory_space.destroy

          searchables = Decidim::SearchableResource.where(resource_type: participatory_space.class.name, resource_id: participatory_space.id)

          expect(searchables.any?).to be false
        end
      end
    end

    describe "Search" do
      # trick to force creating participatory_space2 declared in users of this shared_examples
      let!(:spaces) { [participatory_space, participatory_space2] }
      let(:description2) do
        msg = "Chewie, I will be waiting for your signal. Take care, you two. May the Force be with you. Ow!"
        { ca: "CA:#{msg}", en: "EN:#{msg}", es: "ES:#{msg}" }
      end

      context "when searching by ParticipatorySpace resource_type" do
        it "returns ParticipatorySpace results" do
          Decidim::Search.call("Ow", organization, resource_type: participatory_space.class.name) do
            on(:ok) do |results_by_type|
              results = results_by_type[participatory_space.class.name]
              expect(results[:count]).to eq 2
              expect(results[:results]).to contain_exactly(participatory_space, participatory_space2)
            end
            on(:invalid) { raise("Should not happen") }
          end
        end

        it "allows searching by prefix characters" do
          Decidim::Search.call("wait", organization, resource_type: participatory_space.class.name) do
            on(:ok) do |results_by_type|
              results = results_by_type[participatory_space.class.name]
              expect(results[:count]).to eq 1
              expect(results[:results]).to eq [participatory_space2]
            end
            on(:invalid) { raise("Should not happen") }
          end
        end
      end
    end

    private

    def expect_searchable_resource_to_correspond_to_participatory_space(searchable, space, locale)
      attrs = searchable.attributes.clone
      attrs.delete("id")
      attrs.delete("created_at")
      attrs.delete("updated_at")
      expect(attrs).to eq(expected_searchable_resource_attrs(space, locale))
    end

    def expected_searchable_resource_attrs(space, locale)
      {
        "locale" => locale,
        "decidim_organization_id" => space.organization.id,
        "decidim_participatory_space_id" => space.id,
        "decidim_participatory_space_type" => space.class.name,
        "decidim_scope_id" => space.respond_to?(:decidim_scope_id) ? space.decidim_scope_id : nil,
        "resource_id" => space.id,
        "resource_type" => space.class.name
      }.merge(searchable_resource_attrs_mapper.call(space, locale))
    end
  end
end
