class Users::RegistrationsController < Devise::RegistrationsController
  include Users::OmniauthCallbacksHelper
# before_filter :configure_sign_up_params, only: [:create]
# before_filter :configure_account_update_params, only: [:update]

# GET /resource/sign_up
# def new
#   super
# end

# POST /resource
# def create
#   super
# end

# GET /resource/edit
# def edit
#   super
# end

# PUT /resource
# def update
#   super
# end

# DELETE /resource
  def destroy
    # super
    unless current_user.nil?
      if current_user.email == params[:email]
        oauth_sign_out_url = omniauth_sign_out_url
        ### Update when devise will updated! This is copy-paste from devise code!
        resource.destroy
        Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
        set_flash_message :notice, :destroyed if is_flashing_format?
        yield resource if block_given?
        ### end of update zone
        if oauth_sign_out_url.nil?
          redirect_to root_url
        else
          redirect_to oauth_sign_out_url
        end
      else
        flash[:danger] = t 'person.email_for_account_remove_not_match'
        redirect_to user_root_path
      end
    end
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # You can put the params you want to permit in the empty array.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.for(:sign_up) << :attribute
  # end

  # You can put the params you want to permit in the empty array.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
