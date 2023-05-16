class RenameDependencyToSubjectLink < ActiveRecord::Migration[7.0]
  def change
    rename_table :dependencies, :subject_links
  end
end
