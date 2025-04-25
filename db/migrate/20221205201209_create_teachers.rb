class CreateTeachers < ActiveRecord::Migration[7.0]
  def change
    create_table :teachers, id: false do |t|
      t.references :user, null: false, foreign_key: true, primary_key: true
      t.references :area, null: false, foreign_key: true

      t.timestamps
    end
  end
end

