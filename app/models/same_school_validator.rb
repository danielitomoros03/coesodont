class SameSchoolValidator < ActiveModel::Validator
  def validate(record)
    if same_school(record)
      record.errors.add "No es posible inscribir una asignatura de otra escuela", " sin estar ofertada como PCI"
    end
  end

  private
    def same_school(record)
      (!record.course.offer_as_pci? and !(record.section.school.id.eql? record.enroll_academic_process.school.id))
    end
end
