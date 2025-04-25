class CreateAreas < ActiveRecord::Migration[7.0]
  def change
    create_table :areas do |t|
      t.string :name, null: false, unique: true
      t.references :school, null: false, foreign_key: true
      t.references :parent_area, index: true, foreign_key: { to_table: :areas }
      t.timestamps
    end
  end
end
