# frozen_string_literal: true

shared_examples "manage process components" do
  let!(:participatory_process) do
    create(:participatory_process, :with_steps, organization:)
  end
  let!(:attributes) { attributes_for(:component, participatory_space: participatory_process) }

  let(:step_id) { participatory_process.steps.first.id }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  describe "add a component" do
    before do
      visit decidim_admin_participatory_processes.components_path(participatory_process)
    end

    context "when the process has active steps" do
      before do
        find("button[data-toggle=add-component-dropdown]").click

        within "#add-component-dropdown" do
          find(".dummy").click
        end

        within ".item__edit-form .new_component" do
          fill_in_i18n(
            :component_name,
            "#component-name-tabs",
            **attributes[:name].except("machine_translations")
          )

          within ".global-settings" do
            fill_in_i18n_editor(
              :component_settings_dummy_global_translatable_text,
              "#global-settings-dummy_global_translatable_text-tabs",
              en: "Dummy Text"
            )
            all("input[type=checkbox]").last.click
          end

          within "#panel-step_settings" do
            fill_in_i18n_editor(
              "component_step_settings_#{step_id}_dummy_step_translatable_text",
              "#step-#{step_id}-settings-dummy_step_translatable_text-tabs",
              en: "Dummy Text for Step"
            )
            all("input[type=checkbox]").first.click
          end

          click_on "Add component"
        end
      end

      it "is successfully created" do
        expect(page).to have_admin_callout("successfully")
        expect(page).to have_content(translated(attributes[:name]))
      end

      it "has a successful admin log" do
        visit decidim_admin.root_path
        expect(page).to have_content("created #{translated(attributes[:name])} in #{translated(participatory_process.title)}")
      end

      context "and then edit it" do
        before do
          within "tr", text: translated(attributes[:name]) do
            click_on "Configure"
          end
        end

        it "successfully displays initial values in the form" do
          within ".global-settings" do
            expect(all("input[type=checkbox]").last).to be_checked
          end

          within "#panel-step_settings" do
            expect(all("input[type=checkbox]").first).to be_checked
          end
        end

        it "successfully edits it" do
          click_on "Update"

          expect(page).to have_admin_callout("successfully")
        end
      end
    end

    context "when the process does not have active steps" do
      let!(:participatory_process) do
        create(:participatory_process, organization:)
      end

      before do
        find("button[data-toggle=add-component-dropdown]").click

        within "#add-component-dropdown" do
          find(".dummy").click
        end

        within ".item__edit-form .new_component" do
          fill_in_i18n(
            :component_name,
            "#component-name-tabs",
            en: "My component",
            ca: "La meva funcionalitat",
            es: "Mi funcionalitat"
          )

          within ".global-settings" do
            fill_in_i18n_editor(
              :component_settings_dummy_global_translatable_text,
              "#global-settings-dummy_global_translatable_text-tabs",
              en: "Dummy Text"
            )
            all("input[type=checkbox]").last.click
          end

          within ".default-step-settings" do
            fill_in_i18n_editor(
              :component_default_step_settings_dummy_step_translatable_text,
              "#default-step-settings-dummy_step_translatable_text-tabs",
              en: "Dummy Text for Step"
            )
            all("input[type=checkbox]").first.click
          end

          click_on "Add component"
        end
      end

      it "is successfully created" do
        expect(page).to have_admin_callout("successfully")
        expect(page).to have_content("My component")
      end

      context "and then edit it" do
        before do
          within "tr", text: "My component" do
            click_on "Configure"
          end
        end

        it "successfully displays initial values in the form" do
          within ".global-settings" do
            expect(all("input[type=checkbox]").last).to be_checked
          end

          within ".default-step-settings" do
            expect(all("input[type=checkbox]").first).to be_checked
          end
        end

        it "successfully edits it" do
          click_on "Update"

          expect(page).to have_admin_callout("successfully")
        end
      end
    end
  end

  describe "edit a component" do
    let(:component_name) do
      {
        en: "My component",
        ca: "La meva funcionalitat",
        es: "Mi funcionalitat"
      }
    end

    let!(:component) do
      create(
        :component,
        name: component_name,
        participatory_space: participatory_process,
        step_settings: {
          step_id => { dummy_step_translatable_text: generate_localized_title }
        }
      )
    end

    before do
      visit decidim_admin_participatory_processes.components_path(participatory_process)
    end

    it "updates the component" do
      within ".component-#{component.id}" do
        click_on "Configure"
      end

      within ".edit_component" do
        fill_in_i18n(
          :component_name,
          "#component-name-tabs",
          **attributes[:name].except("machine_translations")
        )

        within ".global-settings" do
          all("input[type=checkbox]").last.click
        end

        within "#panel-step_settings" do
          all("input[type=checkbox]").first.click
        end

        click_on "Update"
      end

      expect(page).to have_admin_callout("successfully")
      expect(page).to have_content(translated(attributes[:name]))

      within "tr", text: translated(attributes[:name]) do
        click_on "Configure"
      end

      within ".global-settings" do
        expect(all("input[type=checkbox]").last).to be_checked
      end

      within "#panel-step_settings" do
        expect(all("input[type=checkbox]").first).to be_checked
      end

      visit decidim_admin.root_path
      expect(page).to have_content("updated #{translated(attributes[:name])} in #{translated(participatory_process.title)}")
    end

    context "when the process does not have active steps" do
      before { participatory_process.steps.destroy_all }

      it "updates the default step settings" do
        within ".component-#{component.id}" do
          click_on "Configure"
        end

        within ".edit_component" do
          within ".default-step-settings" do
            all("input[type=checkbox]").first.click
          end

          click_on "Update"
        end

        expect(page).to have_admin_callout("successfully")

        within "tr", text: "My component" do
          click_on "Configure"
        end

        within ".default-step-settings" do
          expect(all("input[type=checkbox]").first).to be_checked
        end
      end
    end
  end

  describe "publish and unpublish a component" do
    let!(:component) do
      create(:component, participatory_space: participatory_process, published_at:, visible:)
    end

    let(:published_at) { nil }
    let(:visible) { true }

    before do
      visit decidim_admin_participatory_processes.components_path(participatory_process)
    end

    context "when the component is unpublished" do
      it "publishes the component" do
        within ".component-#{component.id}" do
          click_on "Publish"
        end

        within ".component-#{component.id}" do
          expect(page).to have_css(".action-icon--unpublish")
        end
      end

      it "notifies its followers" do
        follower = create(:user, organization: participatory_process.organization)
        create(:follow, followable: participatory_process, user: follower)

        within ".component-#{component.id}" do
          click_on "Publish"
        end

        expect(Decidim::EventPublisherJob).to(have_been_enqueued.with(
                                                "decidim.events.components.component_published", {
                                                  resource: component,
                                                  event_class: "Decidim::ComponentPublishedEvent",
                                                  affected_users: [],
                                                  followers: [follower],
                                                  force_send: false,
                                                  extra: {}
                                                }
                                              ))
      end
    end

    context "when the component is published" do
      let(:published_at) { Time.current }

      it "hides the component from the menu" do
        within ".component-#{component.id}" do
          click_on "Hide"
        end

        within ".component-#{component.id}" do
          expect(page).to have_css(".action-icon--menu-hidden")
        end
      end
    end

    context "when the component is hidden from the menu" do
      let(:published_at) { Time.current }
      let(:visible) { false }

      it "unpublishes the component" do
        within ".component-#{component.id}" do
          click_on "Unpublish"
        end

        within ".component-#{component.id}" do
          expect(page).to have_css(".action-icon--publish")
        end
      end
    end
  end

  describe "reorders a component" do
    let!(:component1) { create(:component, name: { en: "Component 1" }, participatory_space:) }
    let!(:component2) { create(:component, name: { en: "Component 2" }, participatory_space:) }
    let!(:component3) { create(:component, name: { en: "Component 3" }, participatory_space:) }

    before do
      visit participatory_space_components_path(participatory_space)
    end

    it "changes the order of the components" do
      expect(page.text.index("Component 1")).to be < page.text.index("Component 2")
      expect(page.text.index("Component 2")).to be < page.text.index("Component 3")

      first("td.dragging-handle").drag_to(find("tbody.draggable-table tr:last-child"))

      visit current_path

      expect(page.text.index("Component 2")).to be < page.text.index("Component 1")
      expect(page.text.index("Component 1")).to be < page.text.index("Component 3")
    end
  end

  def participatory_space
    participatory_process
  end

  def participatory_space_components_path(participatory_space)
    decidim_admin_participatory_processes.components_path(participatory_space)
  end
end
