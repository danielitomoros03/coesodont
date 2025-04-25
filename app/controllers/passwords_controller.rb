# frozen_string_literal: true
class PasswordsController < Devise::PasswordsController
  skip_before_action :authenticate_user!#, only: [ :edit, :update ]

  # GET /resource/password/new
  def new
   super
  end

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      
      flash[:danger] = resource.errors.full_messages.to_sentence unless resource.errors.empty?

      flash[:warning] = "Si no está seguro del correo registrado en COES, contacte a la administración para que le brinde el apoyo respectivo."
      redirect_back fallback_location: root_path
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
   super
  end

  # PUT /resource/password
  # def update
  #   if params[:user][:password].eql? params[:user][:password_confirmation]
  #     super
  #   else
  #     flash[:error] = 'Las contraseñas no son iguales. Por favor, inténtelo nuevamente.' 
  #     redirect_back fallback_location: root_path
  #   end
  # end


  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      if Devise.sign_in_after_reset_password
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message!(:notice, flash_message)
        resource.after_database_authentication
        sign_in(resource_name, resource)
      else
        set_flash_message!(:notice, :updated_not_active)
      end
      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      set_minimum_password_length
      flash[:danger] = "No se pudo actualizar la contraseña: #{resource.errors.full_messages.to_sentence}"
      redirect_back fallback_location: root_path
    end
  end


  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
