class AddUpdatedPasswordToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :updated_password, :boolean, null: false, default: false
  end
end
