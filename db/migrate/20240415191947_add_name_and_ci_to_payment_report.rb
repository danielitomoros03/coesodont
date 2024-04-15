class AddNameAndCiToPaymentReport < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_reports, :depositor_name, :string
    add_column :payment_reports, :depositor_ci, :string
  end
end
