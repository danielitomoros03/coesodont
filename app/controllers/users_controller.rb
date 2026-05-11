class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :edit_images]

  layout 'logged'
  def edit_images
  end

  def update
    password_change = user_params[:password].present?

    begin
      if @user.update(user_params)
        flash[:success] = '¡Datos guardados con éxito!'
      else
        flash[:danger] = @user.errors.full_messages.to_sentence
      end
    rescue ActionController::ParameterMissing
      flash[:info] = 'Sin cambios realizados'
    rescue StandardError => e
      flash[:danger] = e.message
    end

    # Cambio de clave: cerrar sesión y forzar relogin para que after_sign_in_path_for
    # arme limpia toda la sesión (session[:rol], etc.). La vista edit_password ya advierte
    # al usuario que esto va a ocurrir.
    if password_change && @user.errors.empty?
      sign_out @user
      flash[:success] = 'Contraseña actualizada. Inicia sesión con tu nueva clave.'
      return redirect_to new_user_session_path
    end

    redirect_to(
      if @user.admin?   then rails_admin_path
      elsif @user.teacher? then teacher_session_dashboard_path
      elsif @user.student? then student_session_dashboard_path
      else root_path
      end
    )
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params

      params.require(:user).permit(:email, :first_name, :last_name, :sex, :number_phone, :ci_image, :profile_picture,:password, :password_confirmation)

    end
end
