class CreateAuthorizeds < ActiveRecord::Migration[7.0]
  def change
    create_table :authorizeds do |t|
      t.references :admin, null: false, foreign_key: {primary_key: :user_id, on_delete: :cascade, on_update: :cascade}
      t.references :authorizable, null: false, foreign_key: {primary_key: :id, on_delete: :cascade, on_update: :cascade}
      t.boolean :can_create, default: false
      t.boolean :can_read, default: false
      t.boolean :can_update, default: false
      t.boolean :can_delete, default: false
      t.boolean :can_import, default: false
      t.boolean :can_export, default: false

      t.timestamps
    end
    add_index :authorizeds, [:admin_id, :authorizable_id], unique: true
  end
end
