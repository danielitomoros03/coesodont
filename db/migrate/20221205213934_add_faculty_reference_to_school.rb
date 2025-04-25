class AddFacultyReferenceToSchool < ActiveRecord::Migration[7.0]
  def change
    add_reference :schools, :faculty, index: true
  end
end
