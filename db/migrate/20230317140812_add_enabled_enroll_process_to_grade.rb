class AddEnabledEnrollProcessToGrade < ActiveRecord::Migration[7.0]
  def change
    add_reference :grades, :enabled_enroll_process, index: true, foreign_key: { to_table: :academic_processes }
  end
end
