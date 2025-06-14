# frozen_string_literal: true

# This migration comes from decidim_debates (originally 20250515115545)
class RenameDebatesEndorsementsCountToLikes < ActiveRecord::Migration[7.0]
  def change
    rename_column :decidim_debates_debates, :endorsements_count, :likes_count

    rename_index :decidim_debates_debates,
                 :idx_decidim_debates_debates_on_endorsemnts_count,
                 :index_decidim_debates_debates_on_likes_count
  end
end
