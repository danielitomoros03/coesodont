class ChangeSectionTeacher < ActiveRecord::Migration[7.0]
  def change
    remove_reference :sections, :teacher

    add_reference :sections, :teacher, index: true, foreign_key: {primary_key: :user_id, on_delete: :cascade, on_update: :cascade}, null: true
  end
end
