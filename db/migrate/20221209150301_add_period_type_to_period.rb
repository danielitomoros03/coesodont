class AddPeriodTypeToPeriod < ActiveRecord::Migration[7.0]
  def change
    add_reference :periods, :period_type, index: true
  end
end
