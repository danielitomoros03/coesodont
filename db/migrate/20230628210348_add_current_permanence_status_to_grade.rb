class AddCurrentPermanenceStatusToGrade < ActiveRecord::Migration[7.0]
  def change
    add_column :grades, :current_permanence_status, :integer, default: 0, null: false
  end
end
