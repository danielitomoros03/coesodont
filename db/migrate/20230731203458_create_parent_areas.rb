class CreateParentAreas < ActiveRecord::Migration[7.0]
  def change
    create_table :parent_areas do |t|
      t.string :name
      t.references :school, null: false, foreign_key: true
      t.timestamps
    end
  end
end
