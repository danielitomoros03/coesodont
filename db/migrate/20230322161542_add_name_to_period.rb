class AddNameToPeriod < ActiveRecord::Migration[7.0]
  def change
    add_column :periods, :name, :string
  end
end
