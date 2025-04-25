class CreateEnrollAcademicProcesses < ActiveRecord::Migration[7.0]
  def change
    create_table :enroll_academic_processes do |t|
      t.references :grade, null: false, foreign_key: true
      t.references :academic_process, null: false, foreign_key: true
      t.integer :enroll_status
      t.integer :permanence_status

      t.timestamps
    end
  end
end
