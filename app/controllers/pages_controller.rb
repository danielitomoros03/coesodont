class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def multirols
    @roles = params[:roles]
    @models = models_list
  end

  def home
    reset_session
    redirect_to new_user_session_path
    # Comentar esto mientras tanto
  end

end
