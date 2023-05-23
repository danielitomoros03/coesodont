class UserMailer < ApplicationMailer
  default from: "coes.odon@gmail.com"
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  #
  def welcome
    @greeting = "Hi"

    mail to: "danielito.moros03@gmail.com"
  end

  def enroll_confirmation(id)
    enroll_academic_process = EnrollAcademicProcess.find id
    user = enroll_academic_process.user
    escuela = enroll_academic_process.school
    @sections = enroll_academic_process.sections

    @escuela_name = escuela.name
    @periodo_name = enroll_academic_process.period.name
    @nombre = user.nick_name
    @genero = user.genero
    mail(to: user.email_desc, subject: "¡Confirmación de inscripción en #{@escuela_name} para el Período #{@periodo_name} COES-FAU!")
    
  end

end
