class CreateAdmissionTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_types do |t|
      t.string :name
      t.references :school, null: false, foreign_key: true

      t.timestamps
    end
  end
end
