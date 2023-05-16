class AddIndexToSubjectLinks < ActiveRecord::Migration[7.0]
  def change
    add_index :subject_links, [:prelate_subject_id, :depend_subject_id], unique: true, name: 'link_parent_depend'    
  end
end
