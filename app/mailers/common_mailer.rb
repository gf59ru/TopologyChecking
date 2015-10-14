require 'mail'
require 'erb'
require 'ostruct'

class CommonMailer < ApplicationMailer
  default from: 'spatial.operations@yandex.ru'

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

end
