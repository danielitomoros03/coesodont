class CreateAuthorizables < ActiveRecord::Migration[7.0]
  def change
    create_table :authorizables do |t|
      t.references :area_authorizable, null: false, foreign_key: true
      t.string :klazz, null: false, unique: true
      t.string :description
      t.string :icon

      t.timestamps
    end
    add_index :authorizables, [:klazz, :area_authorizable_id], unique: true
  end
end
