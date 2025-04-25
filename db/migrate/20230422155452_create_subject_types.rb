class CreateSubjectTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :subject_types do |t|
      t.references :study_plan, null: false, foreign_key: true
      t.string :name
      t.string :code
      t.integer :required_credits, null: false, default: 0 

      t.timestamps
    end
  end
end
