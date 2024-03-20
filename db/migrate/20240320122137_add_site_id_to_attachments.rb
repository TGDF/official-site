# frozen_string_literal: true

class AddSiteIdToAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :attachments, :site_id, :bigint

    add_index :attachments, :site_id
  end
end
