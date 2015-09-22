class HomeController < ApplicationController
  include ApplicationHelper

  before_action :set_locale

  def index
    unless current_user.nil?
      puts current_user.id.class.name
      @operation_types = OperationType.all
      @operations = current_user.operations
    end
  end
end
