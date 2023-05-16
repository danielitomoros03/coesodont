class CreateAreaAuthorizables < ActiveRecord::Migration[7.0]
  def change
    create_table :area_authorizables do |t|
      t.string :name, null: false, unique: true
      t.string :description
      t.string :icon

      t.timestamps
    end
  end
end
