class CreateAcademicRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :academic_records do |t|
      t.references :section, null: false, foreign_key: true
      t.references :enroll_academic_process, null: false, foreign_key: true
      t.float :first_q
      t.float :second_q
      t.float :third_q
      t.float :final_q
      t.float :post_q
      t.integer :status_q, default: 0
      t.integer :type_q

      t.timestamps
    end
  end
end
