class CreateDependencies < ActiveRecord::Migration[7.0]
  def change
    create_table :dependencies do |t|
      # t.references :subject, null: false, foreign_key: true
      t.bigint :subject_parent_id, index: true, null: false
      t.bigint :subject_dependent_id, index: true, null: false

      t.timestamps
    end
    add_foreign_key :dependencies, :subjects, index: true, column: :subject_parent_id
    add_foreign_key :dependencies, :subjects, index: true, column: :subject_dependent_id
  end
end
