class SamePeriodValidator < ActiveModel::Validator
  def validate(record)
    if same_period(record)
      record.errors.add "No es posible inscribir una asignatura ofertada en otro periodo, el periodo es #{record.enroll_academic_process.period.name} ", "y la asignatura es del periodo #{record.course.period.name} ."
    end
  end

  private
    def same_period(record)
      not (record.section.period.id.eql? record.enroll_academic_process.period.id)
    end
end
