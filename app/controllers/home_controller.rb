class HomeController < ApplicationController
  include ApplicationHelper

  before_action :clear_return_to
  before_action :set_locale

  def index
    if current_user.nil?
      @wiki = WikiCloth::Parser.new({
                                        :data => I18n.t('help.about.full_description'),
                                        :noedit => true
                                    })
    else
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
    @wiki = WikiCloth::Parser.new({
                                      :data => I18n.t("help.operation_types.#{@operation_type}.text"),
                                      :noedit => true
                                  })
  end

  def about
    @wiki = WikiCloth::Parser.new({
                                      :data => I18n.t('help.about.text'),
                                      :noedit => true
                                  })
  end

  def terms_of_use
    @wiki = WikiCloth::Parser.new({
                                      :data => I18n.t('help.terms_of_use.text'),
                                      :noedit => true
                                  })
  end

  def privacy_policy
    @wiki = WikiCloth::Parser.new({
                                      :data => I18n.t('help.privacy_policy.text'),
                                      :noedit => true
                                  })
  end

  def request_new_operation_type
    if request.method == 'POST'
      session[:return_to] ||= request.referer
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
        flash[:success] = t 'operation_types.request_sent'
        redirect_to home_about_url
      end
    end
  end

  def feedback
    if current_user.nil?
      redirect_to home_about_url
    else
      if request.method == 'POST'
        session[:return_to] ||= request.referer
        question = params[:question]
        operation = Operation.find_by_id params[:operation]
        files = Array.new
        unless params[:files].nil?
          params[:files].each do |file|
            files << {:filename => file.original_filename, :path => file.tempfile.path}
          end
        end
        CommonMailer.support_request(current_user, question, operation, files.to_json).deliver_later
        flash[:success] = t 'feedback.request_sent'
        redirect_to root_url
      else
        @selected_operation = params[:operation_id]
      end
    end
  end

end
