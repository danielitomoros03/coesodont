class ApplicationMailer < ActionMailer::Base
  default from: "FAU@coesfau.com" ## Cambiar cuando se integre Gestor de Correo
  layout "mailer"
end
