class UserMailer < ApplicationMailer
  default from: "coes.faco@gmail.com"
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  #
  def welcome
    @greeting = "Hi"

    mail to: "danielito.moros03@gmail.com"
  end
end
