class RenameColumnsToDependency < ActiveRecord::Migration[7.0]
  def change
    rename_column :dependencies, :subject_parent_id, :prelate_subject_id
    rename_column :dependencies, :subject_dependent_id, :depend_subject_id

  end
end
