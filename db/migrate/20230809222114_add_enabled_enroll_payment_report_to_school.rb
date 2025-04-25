class AddEnabledEnrollPaymentReportToSchool < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :enable_enroll_payment_report, :boolean, default: false, null: false
  end
end
