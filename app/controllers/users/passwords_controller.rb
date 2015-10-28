class Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    user = User.find_first_by_auth_conditions :email => params[:user][:email]
    if user.nil? || user.provider.nil?
      super
    else
      CommonMailer.oauth_password_instructions(user.id).deliver_now
      flash[:info] = I18n.t 'devise.passwords.send_instructions'
      redirect_to new_user_session_path
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
