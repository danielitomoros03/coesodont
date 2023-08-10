class AddRegistrationAmount < ActiveRecord::Migration[7.0]
  def change
    add_column :academic_processes, :registration_amount, :float, default: 0
  end
end
