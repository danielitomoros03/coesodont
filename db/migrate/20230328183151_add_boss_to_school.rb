class AddBossToSchool < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :boss_name, :string, default: ''
  end
end
