class CreateSubjects < ActiveRecord::Migration[7.0]
  def change
    create_table :subjects do |t|
      t.string :code, null: false, unique: true
      t.string :name, null: false, unique: true
      t.boolean :active, default: true
      t.integer :unit_credits, null: false, default: 24
      t.integer :ordinal, null: false, default: 0
      t.integer :qualification_type
      t.integer :modality
      t.references :area, null: false, foreign_key: true

      t.timestamps
    end
  end
end
