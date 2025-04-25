class CreateJoinTableSectionTeacher < ActiveRecord::Migration[7.0]
  def change
    create_join_table :sections, :teachers do |t|
      t.index [:section_id, :teacher_id], unique: true
    end
    add_foreign_key :sections_teachers, :sections, index: true
    add_foreign_key :sections_teachers, :teachers, primary_key: :user_id, index: true
  end
end
