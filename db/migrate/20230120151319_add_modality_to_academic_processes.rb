class AddModalityToAcademicProcesses < ActiveRecord::Migration[7.0]
  def change
    add_column :academic_processes, :modality, :integer, default: 0, null: false
  end
end
