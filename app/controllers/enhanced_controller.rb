class EnhancedController < ActionController::Base
  include ActionController::Live
  before_action :set_paper_trail_whodunnit
  before_action :set_paper_trail_request_info
  rescue_from CanCan::AccessDenied, with: :handle_access_denied

  # Necesario aquí además de ApplicationController porque RailsAdmin se monta
  # sobre este controller (config.parent_controller = 'EnhancedController') y
  # ActionController::Base no hereda del rescue del controller global. Sin
  # esto, el throw :warden por timeout escapa como UncaughtThrowError en
  # /admin/*, y con ActionController::Live incluido acá el catch del middleware
  # queda en otro hilo y no lo alcanza nunca.
  rescue_from UncaughtThrowError do |exception|
    raise exception unless exception.tag == :warden

    reset_session
    flash[:warning] = "Su sesión ha expirado por inactividad. Por favor, ingrese nuevamente."
    redirect_to main_app.new_user_session_path
  end

  def info_for_paper_trail
    { ip: request.remote_ip, user_agent: request.user_agent }
  end

  private

  def set_paper_trail_request_info
    return unless PaperTrail::Version.table_exists?
    cols = PaperTrail::Version.column_names
    info = {}
    info[:ip]         = request.remote_ip  if cols.include?('ip')
    info[:user_agent] = request.user_agent if cols.include?('user_agent')
    PaperTrail.request.controller_info = info
  rescue StandardError
    PaperTrail.request.controller_info = {}
  end

  def handle_access_denied(_exception)
    flash[:error] = 'No está autorizado para acceder a esta página.'
    redirect_back fallback_location: rails_admin_path, allow_other_host: false
  end
end
