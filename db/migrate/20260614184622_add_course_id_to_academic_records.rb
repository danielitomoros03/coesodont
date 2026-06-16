class AddCourseIdToAcademicRecords < ActiveRecord::Migration[7.0]
  def up
    add_column :academic_records, :course_id, :bigint

    execute <<~SQL
      UPDATE academic_records
      SET course_id = sections.course_id
      FROM sections
      WHERE academic_records.section_id = sections.id
    SQL

    # Saneamiento previo al índice único: el import histórico de 2024 dejó academic_records
    # duplicados (misma inscripción + misma asignatura en secciones distintas). Se conserva
    # el más reciente por (enroll, course) y se eliminan el resto, junto con sus qualifications
    # (única FK dependiente), para que add_index unique no aborte el deploy.
    dup_ids = select_values(<<~SQL)
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (
                 PARTITION BY enroll_academic_process_id, course_id
                 ORDER BY updated_at DESC, id DESC) AS rn
        FROM academic_records
        WHERE course_id IS NOT NULL
      ) t WHERE rn > 1
    SQL

    if dup_ids.any?
      list = dup_ids.join(",")
      say "Eliminando #{dup_ids.size} academic_records duplicados (enroll+course): #{list}"
      execute "DELETE FROM qualifications WHERE academic_record_id IN (#{list})"
      execute "DELETE FROM academic_records WHERE id IN (#{list})"
    end

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
