class CreateGrades < ActiveRecord::Migration[7.0]
  def change
    create_table :grades do |t|
      t.references :student, null: false, foreign_key: {primary_key: :user_id, on_delete: :cascade, on_update: :cascade}
      t.references :study_plan, null: false, foreign_key: true
      t.integer :graduate_status
      t.references :admission_type, null: false, foreign_key: true
      t.integer :registration_status
      t.float :efficiency
      t.float :weighted_average
      t.float :simple_average

      t.timestamps
      t.index [:student_id, :study_plan_id], unique: true
    end
  end
end
