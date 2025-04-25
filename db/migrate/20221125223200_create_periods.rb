class CreatePeriods < ActiveRecord::Migration[7.0]
  def change
    create_table :periods do |t|
      t.integer :year, null: false
      t.timestamps
    end
  end
end
