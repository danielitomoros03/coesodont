class EnhancedController < ActionController::Base
  include ActionController::Live
  before_action :set_paper_trail_whodunnit
  before_action :set_paper_trail_request_info
  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  def info_for_paper_trail
    { ip: request.remote_ip, user_agent: request.user_agent }
  end

  private

  def set_paper_trail_request_info
    PaperTrail.request.controller_info = { ip: request.remote_ip, user_agent: request.user_agent }
  end

  def handle_access_denied(_exception)
    flash[:error] = 'No está autorizado para acceder a esta página.'
    redirect_back fallback_location: rails_admin_path, allow_other_host: false
  end
end
