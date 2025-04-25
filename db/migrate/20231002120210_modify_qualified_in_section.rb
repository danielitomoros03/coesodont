class ModifyQualifiedInSection < ActiveRecord::Migration[7.0]
  def change
    change_column :sections, :qualified, :boolean, default: false, null: false
  end
end
