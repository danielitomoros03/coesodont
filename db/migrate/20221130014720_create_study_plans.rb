class CreateStudyPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :study_plans do |t|
      t.string :code
      t.string :name
      t.references :school, null: false, foreign_key: true

      t.timestamps
    end
  end
end
