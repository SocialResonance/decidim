# frozen_string_literal: true

module Decidim
  module Forms
    module Admin
      # This class holds a Form to update response options
      class ResponseOptionForm < Decidim::Form
        include TranslatableAttributes

        attribute :deleted, Boolean, default: false
        attribute :free_text, Boolean

        translatable_attribute :body, String

        validates :body, translatable_presence: true, unless: :deleted

        def to_param
          return id if id.present?

          "questionnaire-question-response-option-id"
        end
      end
    end
  end
end
