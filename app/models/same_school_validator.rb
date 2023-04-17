class SameSchoolValidator < ActiveModel::Validator
  def validate(record)
    if same_school(record)
      record.errors.add "Está seleccionando una sección de #{record.section.school.code} y #{record.id}", "el Procesos Académico es de #{record.enroll_academic_process.school.code}. Ponga atención en la selección."
    end
  end

  private
    def same_school(record)
      not (record.section.school.id.eql? record.enroll_academic_process.school.id)
    end
end
