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

  def download_user_file
    file = UserFile.find_by_id params[:id]
    if file.user == current_user
      send_file "#{Rails.root}#{File::Separator}#{file.file_path}", :filename => (File.basename file.file_path)
    else
      flash[:warning] = I18n.t 'person.only_owner_can_download_file'
      redirect_to root_url
    end
  end

  def destroy_user_file
    file = UserFile.find_by_id params[:id]
    if file.user == current_user
      file.destroy
      flash[:success] = I18n.t 'person.file_deleted'
      redirect_to user_root_url
    else
      flash[:warning] = I18n.t 'person.only_owner_can_delete_file'
      redirect_to root_url
    end
  end


end
