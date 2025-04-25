class ChangeColumnsToArea < ActiveRecord::Migration[7.0]
  def change
    rename_column :areas, :parent_area_id, :other_parent_id
    add_reference :areas, :parent_area
  end
end
