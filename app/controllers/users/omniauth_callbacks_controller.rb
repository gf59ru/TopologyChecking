class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2
    if user = User.from_omniauth(request.env['omniauth.auth'])
      cookies.delete :google_oauth2_approval_prompt
      flash[:notice] = I18n.t( 'devise.omniauth_callbacks.success', kind: 'Google')
      sign_in_and_redirect user, event: :authentication
    else
      # we are not supporting self-service registration, so although
      # user has authenticated at Google and given consent to the app,
      # we are not going to allow the user in
      cookies[:google_oauth2_approval_prompt] = 'force'
      flash[:error] = I18n.t( 'devise.omniauth_callbacks.failure', kind: 'Google', reason: 'account not provisioned')
      redirect_to root_url
    end
  end

  def linkedin
    if user = User.from_omniauth(request.env['omniauth.auth'])
      cookies.delete :linkedin_oauth2_approval_prompt
      flash[:notice] = I18n.t( 'devise.omniauth_callbacks.success', kind: 'Linkedin')
      sign_in_and_redirect user, event: :authentication
    else
      # we are not supporting self-service registration, so although
      # user has authenticated at Google and given consent to the app,
      # we are not going to allow the user in
      cookies[:linkedin_oauth2_approval_prompt] = 'force'
      flash[:error] = I18n.t( 'devise.omniauth_callbacks.failure', kind: 'Google', reason: 'account not provisioned')
      redirect_to root_url
    end
  end

  #
  # def google_oauth2
  #   @user = User.from_omniauth(request.env['omniauth.auth'])
  #
  #   if @user.persisted?
  #     sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
  #     set_flash_message(:notice, :success, :kind => 'Google') if is_navigational_format?
  #   else
  #     session['devise.google_oauth2'] = request.env['omniauth.auth']
  #     redirect_to new_user_registration_url
  #   end
  # end
  #
  # def revoke_google_oauth2
  #   if !current_user.nil? && current_user.provider == 'google_oauth2'
  #     uri = URI('https://accounts.google.com/o/oauth2/revoke')
  #     params = {:token => current_user.password}
  #     uri.query = URI.encode_www_form(params)
  #     response = Net::HTTP.get(uri)
  #     redirect_to destroy_user_session_path
  #   end
  # end
  #
end
