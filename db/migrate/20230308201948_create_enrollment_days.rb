class CreateEnrollmentDays < ActiveRecord::Migration[7.0]
  def change
    create_table :enrollment_days do |t|
      t.references :academic_process, null: false, foreign_key: true
      t.datetime :start
      t.integer :total_duration_hours, limit: 1
      t.integer :max_grades, limit: 2
      t.integer :slot_duration_minutes, limit: 1

      t.timestamps
    end
  end
end
