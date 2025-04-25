class ModifyAcademicRecord < ActiveRecord::Migration[7.0]
  def change
    remove_column :academic_records, :first_q
    remove_column :academic_records, :second_q
    remove_column :academic_records, :third_q
    remove_column :academic_records, :final_q
    remove_column :academic_records, :post_q
    remove_column :academic_records, :status_q
    remove_column :academic_records, :type_q

    add_column :academic_records, :status, :integer, default: 0 #enum [:sin_calificar, :aprobado, :aplazado, :retirado]

  end
end
