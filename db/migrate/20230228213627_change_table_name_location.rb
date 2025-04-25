class ChangeTableNameLocation < ActiveRecord::Migration[7.0]
  def change
    rename_table :locations, :addresses
  end
end
