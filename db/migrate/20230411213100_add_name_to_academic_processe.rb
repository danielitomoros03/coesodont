class AddNameToAcademicProcesse < ActiveRecord::Migration[7.0]
  def change
    add_column :academic_processes, :name, :string
  end
end
