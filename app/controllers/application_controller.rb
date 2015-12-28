class ApplicationController < ActionController::Base
  include ApplicationHelper

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # unless ActionController::Base.consider_all_requests_local
  #   rescue_from Exception do |exception|
  #     redirect_to '/500'
  #   end
  #   # rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
  #   # rescue_from ActionController::RoutingError, :with => :render_not_found
  #   # rescue_from ActionController::UnknownController, :with => :render_not_found
  #   # rescue_from ActionController::UnknownAction, :with => :render_not_found
  # end

  def after_sign_in_path_for(resource)
    clear_return_to
    user_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    clear_return_to
    request.referrer
  end

  def select_locale
    if current_user.nil?
      locale = params[:locale]
      unless locale.nil?
        cookies.permanent[:locale] = locale
        I18n.locale = locale
        back = session.delete(:return_to)
        if back.nil?
          redirect_to :back
        else
          redirect_to back
        end
      end
    else
      flash[:info] = 'Signed in users can select language in their profile settings and save it'
      redirect_to edit_profile_url
    end
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) << :locale
    devise_parameter_sanitizer.for(:sign_up) << :locale
  end

  def render_error(exception)
    puts exception
    render :template => '/error/error500.html.erb', :status => 500
  end

end
