module Users::OmniauthCallbacksHelper

  def omniauth_sign_out_url
    case current_user.provider
      when 'google_oauth2'
        "https://www.google.com/accounts/Logout?continue=https://appengine.google.com/_ah/logout?continue=#{root_url}"
    end
  end

end
