class CreateSchools < ActiveRecord::Migration[7.0]
  def change
    create_table :schools do |t|
      t.string :code, null: false, unique: true
      t.string :name, null: false, unique: true
      t.integer :type_entity, null: false, default: 0
      t.boolean :enable_subject_retreat
      t.boolean :enable_change_course
      t.boolean :enable_dependents
      t.references :period_active, index: true, foreign_key: { to_table: :periods }
      t.references :period_enroll, index: true, foreign_key: { to_table: :periods }


      t.timestamps
    end
  end
end
