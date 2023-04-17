class SamePeriodValidator < ActiveModel::Validator
  def validate(record)
    if same_period(record)
      record.errors.add "Está seleccionando una sección del #{record.section.period.name} y #{record.id}", "el Procesos Académico es #{record.enroll_academic_process.period.name}. Ponga atención en la selección."
    end
  end

  private
    def same_period(record)
      not (record.section.period.id.eql? record.enroll_academic_process.period.id)
    end
end
