class AddVariusToStudent < ActiveRecord::Migration[7.0]
  def change
    add_column :students, :grade_title, :string
    add_column :students, :grade_university, :string
    add_column :students, :graduate_year, :integer
  end
end
