class AddOrderToSpeakers < ActiveRecord::Migration[5.1]
  def change
    add_column :speakers, :order, :integer, default: 0
  end
end
