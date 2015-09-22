class HomeController < ApplicationController
  include ApplicationHelper

  before_action :set_locale

  def index
    unless current_user.nil?
      @operation_types = OperationType.all
      @operations = current_user.operations
    end
  end
end
