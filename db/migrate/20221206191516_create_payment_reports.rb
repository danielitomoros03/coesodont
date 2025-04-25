class CreatePaymentReports < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_reports do |t|
      t.float :amount
      t.string :transaction_id
      t.integer :transaction_type
      t.date :transaction_date
      t.references :origin_bank, null: false, foreign_key: { to_table: :banks }
      t.references :payable, polymorphic: true
      t.timestamps
    end
  end
end
