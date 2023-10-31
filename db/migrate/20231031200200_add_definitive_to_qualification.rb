class AddDefinitiveToQualification < ActiveRecord::Migration[7.0]
  def change
    add_column :qualifications, :definitive, :boolean, default: true, null: false
  end
end
