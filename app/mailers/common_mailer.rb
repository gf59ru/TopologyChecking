require 'mail'
require 'erb'
require 'ostruct'

class CommonMailer < ApplicationMailer
  include ActionView::Helpers::UrlHelper

  default from: 'spatial.operations@yandex.ru'

  def oauth_password_instructions(user_id)
    user = User.find_by_id user_id
    provider = user.provider
    h_provider = (Users::OmniauthCallbacksController.provider_human_name provider).capitalize
    namespace = OpenStruct.new :user => user,
                               :h_provider => h_provider,
                               :link => (link_to (I18n.t 'person.sign_in_oauth', :oauth_provider => h_provider), "#{root_url}users/auth/#{provider}")
    mail = Mail.new do
      from 'spatial.operations@yandex.ru'
      to user.email
      subject I18n.t 'devise.mailer.reset_password_instructions.subject'
      html_part do
        content_type 'text/html; charset=UTF-8'
        body ERB.new(File.read "#{Rails.root}/app/views/common_mailer/oauth_password_instructions.html.erb").result(namespace.instance_eval { binding })
      end
    end
    mail.deliver
  end

  def invoice_request(user, operation_or_sum, file)
    operation = operation_or_sum if operation_or_sum.is_a? Operation
    sum = operation_or_sum unless operation_or_sum.is_a? Operation
    namespace = OpenStruct.new :user => user, :operation => operation, :sum => sum
    mail = Mail.new do
      from 'spatial.operations@yandex.ru'
      to 'spatial.operations@yandex.ru'
      subject 'Запрос на выставление счёта'
      html_part do
        content_type 'text/html; charset=UTF-8'
        body ERB.new(File.read "#{Rails.root}/app/views/common_mailer/invoice_request.html.erb").result(namespace.instance_eval { binding })
      end
      add_file "#{Rails.root}#{File::Separator}#{file}"
    end
    mail.deliver
  end

  def new_operation_type_request(user_or_email, operation_name, description, steps, files)
    user = user_or_email if user_or_email.is_a? User
    email = if user.nil?
              user_or_email
            else
              user.email
            end
    namespace = OpenStruct.new :user => user, :email => email, :operation_name => operation_name, :description => description, :steps => steps
    mail = Mail.new do
      from 'spatial.operations@yandex.ru'
      to 'spatial.operations@yandex.ru'
      subject 'Запрос на создание нового типа операции'
      html_part do
        content_type 'text/html; charset=UTF-8'
        body ERB.new(File.read "#{Rails.root}/app/views/common_mailer/new_operation_type_request.html.erb").result(namespace.instance_eval { binding })
      end
      files = JSON.parse files
      files.each do |file|
        add_file :filename => file['filename'], :content => File.read(file['path'])
      end
    end
    mail.deliver
  end

end
