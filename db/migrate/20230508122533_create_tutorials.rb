class CreateTutorials < ActiveRecord::Migration[7.0]
  def change
    create_table :tutorials do |t|
      t.string :name_function
      t.references :group_tutorial, null: false, foreign_key: true

      t.timestamps
    end
  end
end
