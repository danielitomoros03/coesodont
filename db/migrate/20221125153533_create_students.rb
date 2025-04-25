class CreateStudents < ActiveRecord::Migration[7.0]
  def change
    create_table :students, id: false do |t|
      t.references :user, null: false, foreign_key: true, primary_key: true
      t.boolean :active, default: true
      t.integer :disability
      t.integer :nacionality
      t.integer :marital_status
      t.string :origin_country
      t.string :origin_city
      t.date :birth_date

      t.timestamps
    end
    # add_foreign_key :students, :users, column: :user_id, on_delete: :cascade, on_update: :cascade
  end
end

