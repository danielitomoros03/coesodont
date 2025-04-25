class RemoveOtherParentIdToArea < ActiveRecord::Migration[7.0]
  def change
    remove_column :areas, :other_parent_id
  end
end
