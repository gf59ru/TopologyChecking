class ErrorsController < ApplicationController

  include ApplicationHelper
  before_action :clear_return_to

  def error404
    render :status => :not_found
  end

  def error500
    render :status => :internal_server_error
  end

  def report
    @error_class = params[:class]
    @error_message = params[:message]
    @stacktrace = JSON.parse params[:stacktrace]
    @time = params[:time]
    @user = params[:user] if params[:user] != nil? || params[:user] != ''
  end

  def send_report
    CommonMailer.report_error(params[:class], params[:message], params[:time], params[:stacktrace], params[:user], params[:description]).deliver_later
    flash[:success] = I18n.t 'errors.report_sent'
    redirect_to root_url
  end

end
