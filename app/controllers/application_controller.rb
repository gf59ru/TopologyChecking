class ApplicationController < ActionController::Base
  include ApplicationHelper

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def after_sign_in_path_for(resource)
    user_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    request.referrer
  end

  def select_locale
    if current_user.nil?
      locale = params[:locale]
      unless locale.nil?
        cookies[:locale] = locale
        I18n.locale = locale
        redirect_to :back
      end
    else
      flash[:info] = 'Signed in users can select language in their profile settings and save it'
      redirect_to edit_profile_url
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) << :locale
    devise_parameter_sanitizer.for(:sign_up) << :locale
  end

end
