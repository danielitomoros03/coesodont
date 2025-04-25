class UniqEnrollmentDayValidator < ActiveModel::Validator
  def validate(record)
    if record.academic_process.enrollment_days.where(start: record.start.all_day).any?
      record.errors.add 'Ya tiene una jornada horaria para el día especificado', ''
    end
  end

end