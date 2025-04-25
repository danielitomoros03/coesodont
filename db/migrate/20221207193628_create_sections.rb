class CreateSections < ActiveRecord::Migration[7.0]
  def change
    create_table :sections do |t|
      t.string :code
      t.integer :capacity
      t.references :course, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: {primary_key: :user_id, on_delete: :cascade, on_update: :cascade}
      t.boolean :qualified
      t.integer :modality
      t.boolean :enabled

      t.timestamps
    end
  end
end
