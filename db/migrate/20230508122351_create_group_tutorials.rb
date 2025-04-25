class CreateGroupTutorials < ActiveRecord::Migration[7.0]
  def change
    create_table :group_tutorials do |t|
      t.string :name_group

      t.timestamps
    end
  end
end
