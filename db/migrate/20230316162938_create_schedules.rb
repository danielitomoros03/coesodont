class CreateSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :schedules do |t|
      t.references :section, null: false, foreign_key: true
      t.integer :day
      t.time :starttime
      t.time :endtime

      t.timestamps
    end
  end
end
