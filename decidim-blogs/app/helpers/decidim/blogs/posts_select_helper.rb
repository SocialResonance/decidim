# frozen_string_literal: true

module Decidim
  module Blogs
    # Custom helpers used in posts views
    module PostsSelectHelper
      include Decidim::ApplicationHelper
      include SanitizeHelper

      def fo_post_author_select_field(form, name, _options = {})
        select_options = [
          [current_user.name, current_user.id]
        ]

        select_options << [form.object.author.name, form.object.author.id] unless !form.object.author || select_options.pluck(1).include?(form.object.author.id)

        return form.select(name, select_options) if select_options.size > 1

        form.hidden_field(name, value: select_options.first[1])
      end
    end
  end
end
