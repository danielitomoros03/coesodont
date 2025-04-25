class AddNameToCourse < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :name, :string, index: true
  end
end
