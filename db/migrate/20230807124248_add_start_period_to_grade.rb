class AddStartPeriodToGrade < ActiveRecord::Migration[7.0]
  def change
    add_reference :grades, :start
    add_reference :grades, :start_process, index: true, foreign_key: {to_table: :academic_processes, on_delete: :nullify, on_update: :cascade}, null: true
  end
end
