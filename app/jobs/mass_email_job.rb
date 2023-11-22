class MassEmailJob < ApplicationJob
  queue_as :default

  def perform(emails)
    # Do something later
    email.each do |email|
      welcome(user)
    end
  end
end
