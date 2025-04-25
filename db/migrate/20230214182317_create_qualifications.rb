class CreateQualifications < ActiveRecord::Migration[7.0]
  def change
    create_table :qualifications do |t|
      t.references :academic_record, null: false, foreign_key: true
      t.integer :value, null: false
      t.integer :type_q, null: false, default: 0

      t.timestamps
    end
  end
end
