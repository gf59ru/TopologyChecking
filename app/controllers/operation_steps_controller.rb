class OperationStepsController < ApplicationController
  include ApplicationHelper

  before_action :clear_return_to, :set_locale

  def show
  end

  def new
    if !current_user.nil? && current_user.is_admin
      operation_type_id = params[:operation_type_id]
      if operation_type_id
        @operation_type = OperationType.find_by_id operation_type_id
        if @operation_type
          @operation_step = OperationStep.new
          @operation_step.operation_type_id = @operation_type.id
          @operation_params = Array.new
        else
          flash[:danger] = "Нельзя создать шаг несуществующего типа операции (id типа операции #{operation_type_id})"
          redirect_to root_url
        end
      else
        flash[:danger] = 'Для создания шага операции требуется идентификатор типа операции'
        redirect_to root_url
      end
    else
      flash[:danger] = 'Создавать шаги операций могут только администраторы'
      redirect_to root_url
    end
  end

  def create
    if !current_user.nil? && current_user.is_admin
      ids = params[:param_id]
      names = params[:param_name]
      default_values = params[:param_default_value]
      id_for_delete = params[:delete_param]
      operation_type_id = params[:operation_type_id]
      @operation_type = OperationType.find_by_id operation_type_id unless operation_type_id.nil?

      if @operation_type.nil?
        flash[:danger] = 'Для создания шага операции требуется идентификатор типа операции'
        redirect_to root_url
      else
        @operation_step = OperationStep.new operation_step_params
        @operation_step.operation_type_id = operation_type_id
        @operation_step.order = @operation_type.operation_steps.count
        if params[:add_param].nil? && id_for_delete.nil?
          if @operation_step.save
            ids.each_index do |i|
              if names[i] != ''
                param = OperationParameter.new
                param.operation_step = @operation_step
                param.name = names[i]
                param.default_value = default_values[i]
                param.save
              end
            end
            flash[:success] = 'Создан новый шаг операции'
            redirect_to @operation_type
          else
            render :new
          end
        else
          new_ids = ids.select { |id| id != '' && id.to_i < 0 }
          new_id = new_ids.empty? ? -1 : new_ids.map { |id| id.to_i }.min - 1
          @operation_params = Array.new
          ids.each_with_index do |id, i|
            if id_for_delete != id && names[i] != ''
              @operation_params << {:id => id == '' ? new_id : id.to_i, :name => names[i], :default_value => default_values[i], :is_new => true}
            end
          end
          @operation_type = OperationType.find_by_id operation_type_id
          render :new
        end
      end
    else
      flash[:danger] = 'Создавать шаги операций могут только администраторы'
      redirect_to root_url
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def operation_step_params
    params.require(:operation_step).permit(:operation_type_id, :name, :service_folder, :async, :multiple, :auto)
  end

end
