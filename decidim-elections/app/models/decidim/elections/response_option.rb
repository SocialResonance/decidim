# frozen_string_literal: true

module Decidim
  module Elections
    class ResponseOption < Elections::ApplicationRecord
      include Decidim::TranslatableResource

      default_scope { order(arel_table[:id].asc) }

      translatable_fields :body

      belongs_to :question, class_name: "Decidim::Elections::Question", foreign_key: "decidim_question_id"

      def translated_body
        Decidim::Forms::ResponseOptionPresenter.new(self).translated_body
      end
    end
  end
end
