class PersonsController < ApplicationController
  include ApplicationHelper

  before_action :set_locale

  def profile
    if current_user.nil?
      redirect_to root_url
    end
  end

  def update
    if current_user.nil?
      redirect_to root_path
    else
      current_user.locale = params[:locale]
      current_user.save
      redirect_to user_root_path
    end
  end

end
