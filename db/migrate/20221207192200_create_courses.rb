class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.references :academic_process, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.boolean :offer_as_pci

      t.timestamps
    end
  end
end
