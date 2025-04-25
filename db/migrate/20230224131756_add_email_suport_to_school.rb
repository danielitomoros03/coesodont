class AddEmailSuportToSchool < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :contact_email, :string, default: 'coes.fau@gmail.com', null: false
  end
end
