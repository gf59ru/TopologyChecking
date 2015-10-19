class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def self.provider_human_name(provider)
    case provider
      when 'google_oauth2'.to_sym
        'google'
      else
        provider
    end
  end

  def google_oauth2
    oauth 'google_oauth2'
  end

  def linkedin
    oauth 'linkedin'
  end

  private

  def oauth(provider)
    if user = User.from_omniauth(request.env['omniauth.auth'])
      if User.where('email = ? and provider <> ?', user.email, provider).count > 0
        cookies["#{provider}_approval_prompt"] = 'force'
        flash[:danger] = I18n.t('devise.omniauth_callbacks.failure', kind: provider, reason: (t 'devise.failure.email_already_exists'))
        redirect_to root_url
      else
        cookies.delete "#{provider}_approval_prompt"
        flash[:success] = I18n.t('devise.omniauth_callbacks.success', kind: provider)
        sign_in_and_redirect user, event: :authentication
      end
    else
      cookies["#{provider}_approval_prompt"] = 'force'
      flash[:danger] = I18n.t('devise.omniauth_callbacks.failure', kind: provider, reason: (t 'devise.failure.account_not_provisioned'))
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
