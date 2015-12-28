class OperationTypesController < ApplicationController
  include ApplicationHelper

  before_action :clear_return_to, :set_locale

  def show
    @operation_type = OperationType.find_by_id params[:id]
    @operation_steps = @operation_type.operation_steps
  end

  def new
    # current_user = SessionsController.helpers.current_user cookies
    if !current_user.nil? && current_user.is_admin
      @operation_type = OperationType.new
      # @operation_params = Array.new
    else
      flash[:danger] = 'Создавать типы операций могут только администраторы'
      redirect_to root_url
    end
  end

  def create
    if !current_user.nil? && current_user.is_admin
      # ids = params[:param_id]
      # names = params[:param_name]
      # default_values = params[:param_default_value]
      # id_for_delete = params[:delete_param]

      @operation_type = OperationType.new operation_type_params
      # if params[:add_param].nil? && id_for_delete.nil?
        if @operation_type.save
          # ids.each_index do |i|
          #   if names[i] != ''
          #     param = OperationParameter.new
          #     param.operation_type = @operation_type
          #     param.name = names[i]
          #     param.default_value = default_values[i]
          #     param.save
          #   end
          # end
          flash[:success] = 'Создан новый тип операции'
          redirect_to root_url
        else
          render :new
        end
      # else
      #   new_ids = ids.select { |id| id != '' && id.to_i < 0 }
      #   new_id = new_ids.empty? ? -1 : new_ids.map { |id| id.to_i }.min - 1
      #   @operation_params = Array.new
      #   ids.each_with_index do |id, i|
      #     if id_for_delete != id && names[i] != ''
      #       @operation_params << {:id => id == '' ? new_id : id.to_i, :name => names[i], :default_value => default_values[i], :is_new => true}
      #     end
      #   end
      #   render :new
      # end
    else
      flash[:danger] = 'Создавать типы операций могут только администраторы'
      redirect_to root_url
    end
  end

  def edit
    # current_user = SessionsController.helpers.current_user cookies
    if !current_user.nil? && current_user.is_admin
      @operation_type = OperationType.find_by_id params[:id]
      # @operation_params = @operation_type.operation_parameters.to_a
    else
      flash[:danger] = 'Редактировать типы операций могут только администраторы'
      redirect_to root_url
    end
  end

  def update
    # current_user = SessionsController.helpers.current_user cookies
    if !current_user.nil? && current_user.is_admin
      ids = params[:param_id]
      names = params[:param_name]
      default_values = params[:param_default_value]
      id_for_delete = params[:delete_param]
      @will_remove = params[:ids_for_remove]
      @will_remove = Array.new if @will_remove.nil?

      @operation_type = OperationType.find_by_id params[:id]
      # if params[:add_param].nil? && id_for_delete.nil?
        @operation_type.update_attributes operation_type_params
        if @operation_type.save
          # ids.each_with_index do |id, i|
          #   if names[i] != '' && !(@will_remove.include? id)
          #     param = if id == '' || id.to_i < 0
          #               OperationParameter.new
          #             else
          #               OperationParameter.find_by_id id.to_i
          #             end
          #     param.operation_type = @operation_type
          #     param.name = names[i]
          #     param.default_value = default_values[i]
          #     param.save
          #   end
          # end
          # @will_remove.each do |id|
          #   param = OperationParameter.find_by_id id.to_i
          #   param.delete
          # end
          flash[:success] = 'Тип операции изменён'
          redirect_to root_url
        else
          render :edit
        end
      # else
      #   new_ids = ids.select { |id| id != '' && id.to_i < 0 }
      #   new_id = new_ids.empty? ? -1 : new_ids.map { |id| id.to_i }.min - 1
      #   @operation_params = @operation_type.operation_parameters.to_a.map { |param| {:id => param.id, :name => param.name, :default_value => param.default_value} }
      #   ids.each_with_index do |id, i|
      #     if id_for_delete != id && (id == '' || id.to_i < 0) && names[i] != ''
      #       @operation_params << {:id => id == '' ? new_id : id.to_i, :name => names[i], :default_value => default_values[i], :is_new => true}
      #     end
      #   end
      #   unless id_for_delete.nil? || id_for_delete.to_i <= 0
      #     if @will_remove.include? id_for_delete
      #       @will_remove.delete id_for_delete
      #     else
      #       @will_remove << id_for_delete
      #     end
      #   end
      #   render :edit
      # end
    else
      flash[:danger] = 'Редактировать типы операций могут только администраторы'
      redirect_to root_url
    end
  end

  def destroy
    # current_user = SessionsController.helpers.current_user cookies
    if !current_user.nil? && current_user.is_admin
      @operation_type = OperationType.find_by_id params[:id]
      # @operation_type.operation_parameters.each do |param|
      #   param.delete
      # end
      @operation_type.delete
      flash[:success] = 'Тип операции удалён'
    else
      flash[:danger] = 'Удалять типы операций могут только администраторы'
    end
    redirect_to root_url
  end

  private

  def operation_type_params
    params.require(:operation_type).permit(:name, :description)
  end

end
