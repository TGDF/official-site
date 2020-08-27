# frozen_string_literal: true

class CreateAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :attachments do |t|
      t.string(:type)
      t.string(:record_type, null: true)
      t.bigint(:record_id, null: true)
      t.string(:file)

      t.timestamps
    end
  end
end
