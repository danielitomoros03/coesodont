class AddUniqueIndexToSection < ActiveRecord::Migration[7.0]
  def change
    add_index :sections, [:code, :course_id], unique: true
  end
end
