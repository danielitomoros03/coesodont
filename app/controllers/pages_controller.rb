class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def multirols
    @roles = params[:roles]
    @models = models_list
  end

  def home
    #redirect_to new_user_session_path
  end

end
