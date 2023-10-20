class ApplicationMailer < ActionMailer::Base
  default from: "SOPORTE ODONTOLOGIA <#{School.first&.contact_email}>"
  layout "mailer"
end
