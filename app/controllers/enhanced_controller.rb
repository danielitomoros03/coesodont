class EnhancedController < ActionController::Base
  include ActionController::Live
  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  private

  def handle_access_denied(_exception)
    flash[:error] = 'No está autorizado para acceder a esta página.'
    redirect_back fallback_location: rails_admin_path, allow_other_host: false
  end
end
