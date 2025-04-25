json.extract! payment_report, :id, :amount, :transaction_id, :transaction_type, :transaction_date, :origin_bank_id, :payable_id, :created_at, :updated_at
json.url payment_report_url(payment_report, format: :json)
