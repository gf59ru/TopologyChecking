class HomeController < ApplicationController
  include ApplicationHelper

  before_action :set_locale

  def index
    unless current_user.nil?
      @operation_types = OperationType.all
      @operations = Operation.where 'user_id = ?', current_user.id
    end
  end
end
