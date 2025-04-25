class ApprovedAndEnrollingValidator < ActiveModel::Validator
  def validate(record)
    if approved_and_enrolling(record)
      record.errors.add "#{record.subject.name.upcase} ya fue aprobada", "e intenta inscribirla en un periodo activo para inscirbir. Si desea cargar un histórico, cierre primero la inscrición actual para la escuela e inténtelo nuevamente."
    end
  end

  private
    def approved_and_enrolling(record)
      record.enroll_academic_process.enrolling? and (record.grade.subjects_approved_ids.include? record.subject.id)
    end
end
