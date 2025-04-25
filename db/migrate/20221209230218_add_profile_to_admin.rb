class AddProfileToAdmin < ActiveRecord::Migration[7.0]
  def change
    add_reference :admins, :profile
  end
end
