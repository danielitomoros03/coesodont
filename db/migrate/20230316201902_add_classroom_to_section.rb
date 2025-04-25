class AddClassroomToSection < ActiveRecord::Migration[7.0]
  def change
    add_column :sections, :classroom, :string
  end
end
