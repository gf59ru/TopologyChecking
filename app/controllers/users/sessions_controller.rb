require 'net/http'

class Users::SessionsController < Devise::SessionsController
  include Users::OmniauthCallbacksHelper

# before_filter :configure_sign_in_params, only: [:create]

# GET /resource/sign_in
  def new
    begin
      super
    rescue Exception => e
      puts "new session error: #{e}"
      raise e
    end
  end

# POST /resource/sign_in
  def create
    begin
      session[:return_to] ||= request.referer
      super
    rescue Exception => e
      puts "create session error: #{e}"
      raise e
    end
  end

# DELETE /resource/sign_out
  def destroy
    # super
    unless current_user.nil?
      oauth_sign_out_url = omniauth_sign_out_url
      ### Update when devise will updated! This is copy-paste from devise code!
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
      yield if block_given?
      ### end of update zone
      if oauth_sign_out_url.nil?
        redirect_to root_url
      else
        redirect_to oauth_sign_out_url
      end
    end
  end

# protected

# You can put the params you want to permit in the empty array.
# def configure_sign_in_params
#   devise_parameter_sanitizer.for(:sign_in) << :attribute
# end
end
