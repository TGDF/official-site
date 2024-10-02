# frozen_string_literal: true

class RemoveSlugUniqueIndexInNews < ActiveRecord::Migration[7.1]
  def change
    remove_index :news, :slug
  end
end
