class AddNotNullDependencyToSchool < ActiveRecord::Migration[7.0]
  def change
    change_column :schools, :enable_dependents, :boolean, default: false, null: false
  end
end
