class AddReceivingBankAccountToPaymentReport < ActiveRecord::Migration[7.0]
  def change

    add_reference :payment_reports, :receiving_bank_account, index: true, foreign_key: { to_table: :bank_accounts, on_delete: :nullify, on_update: :cascade}
  end
end
