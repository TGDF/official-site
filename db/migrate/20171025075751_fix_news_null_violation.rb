class FixNewsNullViolation < ActiveRecord::Migration[5.1]
  def change
    change_column_null :news, :title, true
    change_column_null :news, :content, true
  end
end
