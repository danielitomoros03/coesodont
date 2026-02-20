class MassEmailJob < ApplicationJob
  queue_as :default

  def perform(users)
    users.each do |user|
      UserMailer.welcome(user).deliver_now
    rescue StandardError => e
      Rails.logger.error "MassEmailJob: Error enviando email a #{user.try(:email)}: #{e.message}"
    end
  end
end
