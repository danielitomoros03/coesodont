class AddCodeToAdmissionType < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_types, :code, :string
  end
end
