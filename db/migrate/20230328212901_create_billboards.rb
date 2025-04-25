class CreateBillboards < ActiveRecord::Migration[7.0]
  def change
    create_table :billboards do |t|
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
