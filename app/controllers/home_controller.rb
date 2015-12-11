class HomeController < ApplicationController
  include ApplicationHelper

  before_action :set_locale

  def index
    unless current_user.nil?
      @operation_types = OperationType.all
      @operations = current_user.operations.order :created_at => :desc
    end
  end

  def contacts
  end

  def service_info
  end

  def operation_types_help
    @operation_type = params[:operation_type]
  end

  def about
  end

  def terms_of_use
  end

  def request_new_operation_type
    if request.method == 'POST'
      operation_name = params[:name]
      description = params[:description]
      errors = Array.new
      errors << (t 'operation_types.new_name') if operation_name == ''
      errors << (t 'operation_types.new_description') if description == ''
      steps = params[:steps]

      if current_user.nil?
        email = params[:email]
        if email.nil? || email == ''
          errors << (t 'operation_types.feedback_email')
        end
      end
      if errors.count > 0
        flash[:warning] = "#{t 'operation_types.request_fields_missed'}: #{errors.join(', ')}"
        render :request_new_operation_type
      else
        files = Array.new
        unless params[:files].nil?
          params[:files].each do |file|
            files << {:filename => file.original_filename, :path => file.tempfile.path}
          end
        end
        CommonMailer.new_operation_type_request(current_user.nil? ? email : current_user, operation_name, description, steps, files.to_json).deliver_later
        flash[:success] = t 'operation_types.request_delivered'
        redirect_to home_about_url
      end
    end
  end

end
