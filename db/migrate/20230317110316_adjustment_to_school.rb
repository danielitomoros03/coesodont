class AdjustmentToSchool < ActiveRecord::Migration[7.0]
  def change
    remove_column :schools, :period_active_id
    remove_column :schools, :period_enroll_id
    add_reference :schools, :active_process, index: true, foreign_key: { to_table: :academic_processes }
    add_reference :schools, :enroll_process, index: true, foreign_key: { to_table: :academic_processes }

  end
end
