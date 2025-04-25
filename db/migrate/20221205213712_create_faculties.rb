class CreateFaculties < ActiveRecord::Migration[7.0]
  def change
    create_table :faculties do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
  end
end
