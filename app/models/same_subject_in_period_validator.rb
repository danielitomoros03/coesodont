class SameSubjectInPeriodValidator < ActiveModel::Validator
  def validate(record)
    if same_course_in_period(record)
      record.errors.add "#{record.subject.name.upcase} ya fue inscrita", "en éste período (#{record.enroll_academic_process.period.name})"
    end
  end

  private
    def same_course_in_period(record)
      subject_ids = record.enroll_academic_process.subjects.ids
      subject_ids.include? record.subject.id
    end
end
