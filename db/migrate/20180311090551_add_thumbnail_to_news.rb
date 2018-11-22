# frozen_string_literal: true

class AddThumbnailToNews < ActiveRecord::Migration[5.1]
  def change
    add_column :news, :thumbnail, :string
  end
end
