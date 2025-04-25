class AddProcessBeforeToAcademicProcess < ActiveRecord::Migration[7.0]
  def change
    add_reference :academic_processes, :process_before, foreign_key: { to_table: :academic_processes }
  end
end
