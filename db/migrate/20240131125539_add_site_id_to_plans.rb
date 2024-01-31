class AddSiteIdToPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :plans, :site_id, :bigint, null: true, index: true
  end
end
