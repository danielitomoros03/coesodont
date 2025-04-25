class AddPasswordTokenToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      ## Recoverable for Password
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
    end

    add_index :users, :reset_password_token, unique: true
  end
end
