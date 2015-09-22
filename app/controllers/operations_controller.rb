require 'net/https'
require 'json'
require 'fileutils'
# require 'zip'

class OperationsController < ApplicationController
  # options = {}
  # options.merge!({:port => Rails.application.config.ssl_port}) if defined? Rails.application.config.ssl_port
  # force_ssl options
  include OperationsHelper, ApplicationHelper

  before_action :set_locale


  def cancel_current_job
    @operation = Operation.find_by_id params[:id]
    if !current_user.nil? && current_user.id == @operation.user_id
      #http://qwerty-3:6080/arcgis/rest/services/TopologyChecking/ValidateAndZip/GPServer/ValidateAndZip/jobs/jfd3d90f711d44a71907a9dc8bff81e33/cancel
    else
      flash[:danger] = I18n.t 'operations.only_owner_can_cancel'
      redirect_to root_url
    end
  end

  def next_step
    @operation = Operation.find_by_id params[:id]
    if !current_user.nil? && current_user.id == @operation.user_id
      step = @operation.step
      step = 0 if step.nil?
      case step
        when 0
          gdb = params[:gdb]
          date_stamp = "#{DateTime.now.strftime '%y%m%d%H%M%S'}"
          filename = "#{current_user.id}#{date_stamp}.zip"

          arcgis_folder = '\\\\qwerty-3\\AGS\\'
          user_arcgis_folder = "#{arcgis_folder}#{current_user.id}"
          FileUtils.mkdir_p user_arcgis_folder unless File.directory? user_arcgis_folder
          gdb_arcgis_folder = "#{user_arcgis_folder}\\#{date_stamp}"
          FileUtils.mkdir_p gdb_arcgis_folder unless File.directory? gdb_arcgis_folder
          arcgis_zip = "#{gdb_arcgis_folder}\\#{filename}"
          FileUtils.copy gdb.tempfile, arcgis_zip
          set_operation_value @operation, arcgis_zip, OperationParameter::PARAM_UPLOADED_GDB_ZIP

          run_op = run_operation unzip_and_prepare, {:zip => arcgis_zip}
          job_id = run_op[:job_id]
          set_operation_value @operation, run_op[:status], OperationParameter::PARAM_UNZIP_JOB_STATE
          set_operation_value @operation, job_id, OperationParameter::PARAM_UNZIP_JOB_ID
          set_operation_value @operation, "#{unzip_and_prepare}/jobs/#{job_id}", OperationParameter::PARAM_UNZIP_JOB_URL

          @operation.step = 1
          @operation.save
        when 1
          check_unzipping_and_preparing @operation
        when 2
          class_set = params[:class_set]
          rule_type = params[:rule_type]
          fc1 = params[:fc1]
          fc2 = params[:fc2]
          rule_order = params[:rule_order]
          if rule_order.nil?
            rules_orders = (operation_values @operation, OperationParameter::PARAM_RULE_JSON).maximum('value_order')
            if rules_orders.nil?
              rule_order = 1
            else
              rule_order = rules_orders + 1
            end
          else
            rule_order = rule_order.to_i
          end
          fc1 = nil if fc1 == ''
          fc2 = nil if fc2 == ''
          saved_rule = operation_value @operation, OperationParameter::PARAM_RULE_JSON, rule_order
          saved_rule = JSON.parse(saved_rule) unless saved_rule.nil?
          unless saved_rule.nil?
            if class_set != saved_rule['class_set']
              fc1 = nil
              rule_type = ''
            end
            if fc1 != saved_rule['fc1']
              rule_type = ''
            end
          end
          unless rule_type != '' && (saved_rule.nil? || rule_types[rule_type.to_i][:rule] == saved_rule['rule'])
            fc2 = nil
          end
          is_filled = (operation_values @operation, OperationParameter::PARAM_RULE_JSON).count == 0
          unless class_set == '' || class_set.nil?
            rule_str = OperationsController.helpers.rule_types[rule_type.to_i] unless rule_type.nil? || rule_type == ''
            rule = {
                :class_set => class_set
            }
            rule.merge!({:fc1 => fc1}) unless fc1.nil?
            rule.merge!({:rule => rule_str[:rule]}) unless rule_str.nil?
            rule.merge!({:fc2 => fc2}) unless fc2.nil?
            is_filled = rule_is_filled rule.to_json, false
            if is_filled && !params[:add_topology_rule].nil?
              rule.merge!({:added => true})
            end
            set_operation_value @operation, rule.to_json, OperationParameter::PARAM_RULE_JSON, rule_order
          end
          unless params[:add_topology_rule].nil?
            if is_filled
              rules_orders = (operation_values @operation, OperationParameter::PARAM_RULE_JSON).maximum('value_order')
              set_operation_value @operation, {}.to_json, OperationParameter::PARAM_RULE_JSON, (rules_orders.nil? ? 1 : rules_orders + 1)
            else
              flash[:warning] = I18n.t 'operations.finish_rule_before_add_new'
            end
          end
          unless params[:force_next_step].nil?
            rules = (operation_values @operation, OperationParameter::PARAM_RULE_JSON).select('value')
            rules = rules.to_a.select { |rule| rule_is_filled rule.value }
            if rules.count > 0
              # rules = rules.to_a.map { |rule| JSON.parse rule.value }
              # run_op = run_operation validate_and_zip,
              #                        {
              #                            :gdb => operation_value(@operation, OperationParameter::PARAM_UPLOADED_GDB_PATH),
              #                            :rules => rules.to_json
              #                        }
              # job_id = run_op[:job_id]
              # set_operation_value @operation, run_op[:status], OperationParameter::PARAM_VALIDATE_JOB_STATE
              # set_operation_value @operation, job_id, OperationParameter::PARAM_VALIDATE_JOB_ID
              # set_operation_value @operation, "#{validate_and_zip}/jobs/#{job_id}", OperationParameter::PARAM_VALIDATE_JOB_URL
              #
              @operation.state = Operation::STATE_RULES_ACCEPTING
              @operation.step = 3
              @operation.save
              flash[:success] = I18n.t 'operations.topology_rules_created'
            else
              flash[:warning] = I18n.t 'operations.need_at_least_one_rule'
            end
          end
        when 3
          if @operation.state == Operation::STATE_RULES_ACCEPTING.to_s
            if params[:return_rules_editing].nil?
              rules = (operation_values @operation, OperationParameter::PARAM_RULE_JSON).select('value')
              rules = rules.to_a.select { |rule| rule_is_filled rule.value }
              rules = rules.to_a.map { |rule| JSON.parse rule.value }
              run_op = run_operation validate_and_zip,
                                     {
                                         :gdb => operation_value(@operation, OperationParameter::PARAM_UPLOADED_GDB_PATH),
                                         :rules => rules.to_json
                                     }
              job_id = run_op[:job_id]
              set_operation_value @operation, run_op[:status], OperationParameter::PARAM_VALIDATE_JOB_STATE
              set_operation_value @operation, job_id, OperationParameter::PARAM_VALIDATE_JOB_ID
              set_operation_value @operation, "#{validate_and_zip}/jobs/#{job_id}", OperationParameter::PARAM_VALIDATE_JOB_URL
              @operation.state = Operation::STATE_STARTED
              @operation.save
              flash[:success] = I18n.t 'operations.topology_rules_accepted'
            else
              @operation.state = Operation::STATE_RULES_CREATING
              @operation.step = 2
              @operation.save
            end
          else
            check_validating_and_zipping @operation
          end
      end
      redirect_to @operation
    else
      flash[:danger] = I18n.t 'operations.only_owner_can_work'
      redirect_to root_url
    end
  end

  def check_validating_and_zipping(operation)
    job_uri = operation_value operation, OperationParameter::PARAM_VALIDATE_JOB_URL
    result = check_operation validate_and_zip, (operation_value operation, OperationParameter::PARAM_VALIDATE_JOB_ID), job_uri
    read_messages result, operation, OperationParameter::PARAM_VALIDATE_JOB_MESSAGE, OperationParameter::PARAM_VALIDATE_JOB_WARNING, OperationParameter::PARAM_VALIDATE_JOB_ERROR, OperationParameter::PARAM_VALIDATE_JOB_EMPTY, OperationParameter::PARAM_VALIDATE_JOB_ABORT

    job_state = result['jobStatus'] unless result.nil?
    unless job_state.nil?
      set_operation_value operation, job_state, OperationParameter::PARAM_VALIDATE_JOB_STATE
      case job_state
        when 'esriJobSucceeded'
          set_operation_value operation, result['results_values']['zip_path'], OperationParameter::PARAM_RESULT_ZIP_PATH
          operation.step = 4
          operation.state = (current_user.balance >= 0 || operation.cost < Operation::FREE_THRESHOLD) ? Operation::STATE_DONE : Operation::STATE_DONE_BUT_NOT_ACCESSIBLE
          operation.save
          flash[:success] = I18n.t 'operations.topology_validated'
        when 'esriJobFailed'
          operation.state = Operation::STATE_FAILED
          operation.save
          flash[:danger] = I18n.t 'operations.can_not_validate_topology'
        when 'esriJobCancelling', 'esriJobCancelled'
          operation.state = Operation::STATE_CANCELLED
          operation.save
          flash[:warning] = I18n.t 'operations.topology_validation_cancelled'
      end
    end
  end

  def delete_rule
    @operation = Operation.find_by_id params[:id]
    if !current_user.nil? && current_user.id == @operation.user_id
      if @operation.step == 2
        rule_order = params[:order]
        rule = operation_value @operation, OperationParameter::PARAM_RULE_JSON, rule_order
        if rule.nil?
          flash[:warning] = I18n.t 'operations.can_not_remove_rule'
        else
          remove_operation_value @operation, OperationParameter::PARAM_RULE_JSON, rule_order
        end
      else
        flash[:warning] = I18n.t 'operations.can_not_remove_rule'
      end
      redirect_to @operation
    else
      flash[:danger] = I18n.t 'operations.only_owner_can_work'
      redirect_to root_url
    end
  end

  def show
    @operation = Operation.find_by_id params[:id]
    if !current_user.nil? && current_user.id == @operation.user_id
      if @operation.state == Operation::STATE_DONE_BUT_NOT_ACCESSIBLE && current_user.balance >= 0
        @operation.state = Operation::STATE_DONE
        @operation.save
      end
      case @operation.step
        when 1
          check_unzipping_and_preparing @operation
        when 3
          if @operation.state == Operation::STATE_RULES_ACCEPTING.to_s
          else
            check_validating_and_zipping @operation
          end
      end
      @operation_type = OperationType.find_by_id @operation.operation_type_id
    else
      flash[:danger] = I18n.t 'operations.only_owner_can_open'
      redirect_to root_url
    end
  end

  def new
    @operation_type = params[:operation_type_id]
    @operation = Operation.new
  end

  def create
    unless current_user.nil?
      @operation = Operation.new operation_params
      @operation.user_id = current_user.id
      @operation.created = DateTime.now
      @operation.state = Operation::STATE_CREATED
      if @operation.save
        flash[:success] = I18n.t 'operations.operation_created'
        redirect_to @operation
      else
        render 'new'
      end
    end
  end

  def edit
  end

  def update
  end

  def destroy
    @operation = Operation.find_by_id params[:id]
    if !current_user.nil? && current_user.id == @operation.user_id
      @operation.delete
      flash[:success] = I18n.t 'operations.removed'
    else
      flash[:danger] = I18n.t 'operations.only_owner_can_delete'
    end
    redirect_to root_url
  end

  def download
    operation_id = params[:operation]
    if operation_id.nil?
      flash[:danger] = I18n.t 'operations.too_few_params_for_download'
      redirect_to root_url
    else
      operation = Operation.find_by_id operation_id
      if operation.nil?
        flash[:danger] = I18n.t 'operations.too_few_params_for_download'
        redirect_to root_url
      else
        if !current_user.nil? && current_user.id == operation.user_id
          if current_user.balance < 0 && operation.cost > Operation::FREE_THRESHOLD
            flash[:danger] = I18n.t 'operations.sorry_balance'
            redirect_to operation
          else
            file_param_id = params[:file_param_id]
            path = operation_value operation, file_param_id
            send_file path, :filename => 'result.zip', :type => 'application/zip'
          end
        else
          flash[:danger] = I18n.t 'operations.only_owner_can_download'
          redirect_to root_url
        end
      end
    end
  end

  def pay
    @operation = Operation.find_by_id params[:id]
    if !current_user.nil? && current_user.id == @operation.user_id
      if !arcgis_services_folder.nil? && (@operation.cost.nil? || @operation.cost < Operation::FREE_THRESHOLD)
        flash[:warning] = t 'operation_is_free'
        redirect_to @operation
      else
        uri = URI.encode "https://secure.acquiropay.com?product_id=#{@operation.id}&amount=#{@operation.cost.nil? ? 0 : @operation.cost}&cf=sandbox_pay&cb_url=#{pay_callback_url}&ok_url=#{pay_ok_url}&ko_url=#{pay_ko_url}"
        uri = URI uri
        # json = nil
        http = Net::HTTP.new uri.host, uri.port
        http.use_ssl = true
        # http.ssl_version = 'SSLv3'
        # http.ssl_version = 'SSLv2'
        http.ssl_version = 'SSLv23_client'
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = http.get uri.request_uri
        # puts "acquiro pay response body:\n#{response.body}"
        render response.body
        # if json.nil?
        #   flash[:warning] = 'pay is nil'
        #   redirect_to root_url
        #   else
        #   flash[:success] = 'paid'
        #   redirect_to @operation
        # end
      end
    else
      flash[:danger] = I18n.t 'operations.only_owner_can_work'
      redirect_to root_url
    end
  end

  def pay_callback
    puts "callback parameters: #{params}"
    redirect_to root_url
  end

  def pay_ok
    puts "pay_ok parameters: #{params}"
    redirect_to root_url
  end

  def pay_ko
    puts "pay_ko parameters: #{params}"
    redirect_to root_url
  end

  private

  def operation_params
    params.require(:operation).permit(:operation_type_id, :created, :launched, :completed, :state, :result, :description)
  end

  def check_unzipping_and_preparing(operation)
    job_id = OperationValue.where('operation_id = ? and operation_parameter_id = ?', operation.id, OperationParameter::PARAM_UNZIP_JOB_ID).first
    if job_id.nil?
      operation.step = 0
      operation.save
    else
      job_uri = operation_value operation, OperationParameter::PARAM_UNZIP_JOB_URL
      result = check_operation unzip_and_prepare, (operation_value operation, OperationParameter::PARAM_UNZIP_JOB_ID), job_uri
      read_messages result, operation, OperationParameter::PARAM_UNZIP_JOB_MESSAGE, OperationParameter::PARAM_UNZIP_JOB_WARNING, OperationParameter::PARAM_UNZIP_JOB_ERROR, OperationParameter::PARAM_UNZIP_JOB_EMPTY, OperationParameter::PARAM_UNZIP_JOB_ABORT

      job_state = result['jobStatus']
      set_operation_value operation, job_state, OperationParameter::PARAM_UNZIP_JOB_STATE
      case job_state
        when 'esriJobSucceeded'
          set_operation_value operation, result['results_values']['gdb'], OperationParameter::PARAM_UPLOADED_GDB_PATH
          set_operation_value operation, result['results_values']['classes'].to_json, OperationParameter::PARAM_CLASSES
          classes = result['results_values']['classes']
          polygons_count = 0
          lines_count = 0
          points_count = 0
          classes.each do |fcs|
            fcs['fcs'].each do |fc|
              count = fc['count'].to_i
              case fc['shapeType']
                when 'Polyline'
                  lines_count += count
                when 'Polygon'
                  polygons_count += count
                when 'Point'
                  points_count += count
              end
            end
          end
          operation.cost = polygons_count + lines_count + points_count
          operation.step = 2
          operation.state = Operation::STATE_RULES_CREATING
          operation.save
          # if cost > Operation::FREE_THRESHOLD
          #   flash[:success] = I18n.t 'operations.gdb_unzipped_and_checked_with_reserve', :cost => cost
          # else
          flash[:success] = I18n.t 'operations.gdb_unzipped_and_checked'
        # end
        when 'esriJobFailed'
          operation.step = 0
          operation.state = Operation::STATE_CREATED
          operation.save
          flash[:danger] = I18n.t 'operations.can_not_unzip_and_prepare'
        when 'esriJobCancelling', 'esriJobCancelled'
          operation.step = 0
          operation.state = Operation::STATE_CREATED
          operation.save
          flash[:warning] = I18n.t 'operations.unzip_and_prepare_cancelled'
      end
    end
  end

  def execute_task(service_folder, params)
    url = "#{service_folder}/execute?env%3AoutSR=&env%3AprocessSR=&returnZ=false&returnM=false&f=pjson"
    params.each do |param|
      url = "#{url}&#{param[0]}=#{param[1]}"
    end
    uri = URI.encode url
    uri = URI uri
    json = nil
    Net::HTTP.start uri.host, uri.port do |job_http|
      request = Net::HTTP::Get.new uri.request_uri
      response = job_http.request request
      json = JSON.parse response.body
    end
    json
  end

  def run_operation(service_folder, params)
    url = "#{service_folder}/submitJob?env%3AoutSR=&env%3AprocessSR=&returnZ=false&returnM=false&f=pjson"
    params.each do |param|
      url = "#{url}&#{param[0]}=#{param[1]}"
    end
    uri = URI.encode url
    uri = URI uri
    job_id = nil
    json = nil
    Net::HTTP.start uri.host, uri.port do |http|
      request = Net::HTTP::Get.new uri.request_uri
      response = http.request request
      json = JSON.parse response.body
      job_id = json['jobId']
      job_uri = URI.encode "#{service_folder}/jobs/#{json['jobId']}?f=pjson"
      job_uri = URI job_uri
      Net::HTTP.start job_uri.host, job_uri.port do |job_http|
        job_request = Net::HTTP::Get.new job_uri.request_uri
        job_response = job_http.request job_request
        json = JSON.parse job_response.body
      end
    end
    {
        :job_id => job_id,
        :status => json['jobStatus']
    }
  end

  def check_operation(service_folder, job_id, job_uri)
    job_uri = URI.encode "#{job_uri}?f=pjson"
    job_uri = URI job_uri
    json = nil
    Net::HTTP.start job_uri.host, job_uri.port do |job_http|
      job_request = Net::HTTP::Get.new job_uri.request_uri
      job_response = job_http.request job_request
      json = JSON.parse job_response.body
    end
    unless json['results'].nil?
      result_json = Hash.new
      json['results'].each do |result|
        param_uri = URI.encode "#{service_folder}/jobs/#{job_id}/#{result[1]['paramUrl']}?f=pjson"
        param_uri = URI param_uri
        Net::HTTP.start job_uri.host, job_uri.port do |job_http|
          param_request = Net::HTTP::Get.new param_uri.request_uri
          param_response = job_http.request param_request
          param_json = JSON.parse param_response.body
          puts param_json
          result_json.store param_json['paramName'], param_json['value']
        end
      end
      json.store 'results_values', result_json
    end
    json
  end

  def read_messages(result, operation, param_type_message, param_type_warning, param_type_error, param_type_empty, param_type_abort)
    unless result.nil? || result['messages'].nil?
      result['messages'].each_with_index do |message, index|
        param_type = case message['type']
                       when 'esriJobMessageTypeInformative'
                         param_type_message
                       when 'esriJobMessageTypeWarning'
                         param_type_warning
                       when 'esriJobMessageTypeError'
                         param_type_error
                       when 'esriJobMessageTypeEmpty'
                         param_type_empty
                       when 'esriJobMessageTypeAbort'
                         param_type_abort
                     end
        set_operation_value operation, message['description'], param_type, index
      end
    end
  end

  def unzip_and_prepare
    "#{arcgis_services_folder}/UnzipAndPrepare/GPServer/UnzipAndPrepare" unless arcgis_services_folder.nil?
  end

  def validate_and_zip
    "#{arcgis_services_folder}/ValidateAndZip/GPServer/ValidateAndZip" unless arcgis_services_folder.nil?
  end

end
