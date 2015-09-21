class WelcomeController < ApplicationController

  def home
    current_user = WelcomeController.helpers.current_user cookies
    unless current_user.nil?

      @operation_types = OperationType.all
      @operations = Operation.where 'user_id = ?', current_user.id
    end
  end

end
