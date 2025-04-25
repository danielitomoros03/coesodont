class AddNumbersToEnrollAcademicProcess < ActiveRecord::Migration[7.0]
  def change
    add_column :enroll_academic_processes, :efficiency, :float, default: 1.0
    add_column :enroll_academic_processes, :simple_average, :float, default: 0.0
    add_column :enroll_academic_processes, :weighted_average, :float, default: 0.0

  end
end
