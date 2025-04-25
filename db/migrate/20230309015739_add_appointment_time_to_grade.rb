class AddAppointmentTimeToGrade < ActiveRecord::Migration[7.0]
  def change
    add_column :grades, :appointment_time, :datetime 
    add_column :grades, :duration_slot_time, :integer
  end
end
