class AddCourseIdToAcademicRecords < ActiveRecord::Migration[7.0]
  def up
    add_column :academic_records, :course_id, :bigint

    execute <<~SQL
      UPDATE academic_records
      SET course_id = sections.course_id
      FROM sections
      WHERE academic_records.section_id = sections.id
    SQL

    change_column_null :academic_records, :course_id, false
    add_foreign_key :academic_records, :courses
    add_index :academic_records, [:enroll_academic_process_id, :course_id],
              unique: true,
              name: "index_academic_records_on_enroll_and_course"
  end

  def down
    remove_index :academic_records, name: "index_academic_records_on_enroll_and_course"
    remove_foreign_key :academic_records, :courses
    remove_column :academic_records, :course_id
  end
end
