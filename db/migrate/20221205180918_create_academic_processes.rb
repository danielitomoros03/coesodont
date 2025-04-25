class CreateAcademicProcesses < ActiveRecord::Migration[7.0]
  def change
    create_table :academic_processes do |t|
      t.references :school, null: false, foreign_key: true
      t.references :period, null: false, foreign_key: true
      t.integer :max_credits
      t.integer :max_subjects

      t.timestamps
    end
  end
end
