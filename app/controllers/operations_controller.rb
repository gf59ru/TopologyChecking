require 'net/http'
require 'json'
require 'fileutils'
# require 'zip'

class OperationsController < ApplicationController
  include ErrorsHelper
  include ApplicationHelper

  before_action :clear_return_to, :set_locale

  JOB_IS_STILL_RUNNING = 1

  PAYMENT_FROM_CARD = 'from_card'
  PAYMENT_FROM_BALANCE = 'from_balance'
  PAYMENT_SHOW_REQUISITES = 'show_requisites'
  PAYMENT_INVOICE_REQUEST = 'invoice_request'

  skip_before_action :verify_authenticity_token, :only => [:pay_callback, :pay_ok, :pay_ko]
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
      saved_rules_query = @operation.values OperationParameter::PARAM_RULE_JSON
      case step
        when 0
          gdb = params[:gdb]
          date_stamp = "#{Time.zone.now.strftime '%y%m%d%H%M%S'}"
          filename = "#{current_user.id}#{date_stamp}.zip"

          arcgis_folder = ENV['ARCGIS_REGISTERED_FOLDER']
          user_arcgis_folder = "#{arcgis_folder}#{File::Separator}#{current_user.id}"
          FileUtils.mkdir_p user_arcgis_folder unless File.directory? user_arcgis_folder
          gdb_arcgis_folder = "#{user_arcgis_folder}#{File::Separator}#{date_stamp}"
          FileUtils.mkdir_p gdb_arcgis_folder unless File.directory? gdb_arcgis_folder
          arcgis_zip = "#{gdb_arcgis_folder}#{File::Separator}#{filename}"
          FileUtils.copy gdb.tempfile, arcgis_zip
          @operation.set_value arcgis_zip, OperationParameter::PARAM_UPLOADED_GDB_ZIP

          run_op = run_operation OperationsController.unzip_and_prepare, {:zip => arcgis_zip}
          job_id = run_op[:job_id]
          @operation.set_value run_op[:status], OperationParameter::PARAM_UNZIP_JOB_STATE
          @operation.set_value job_id, OperationParameter::PARAM_UNZIP_JOB_ID
          job_url = "#{OperationsController.unzip_and_prepare}/jobs/#{job_id}"
          @operation.set_value job_url, OperationParameter::PARAM_UNZIP_JOB_URL
          Delayed::Job.enqueue UnzipAndPrepareJob.new(@operation.id)

          @operation.step = 1
          @operation.save
        when 1
          Delayed::Job.enqueue UnzipAndPrepareJob.new(@operation.id)
        when 2
          class_set = params[:class_set]
          cluster_tolerance = params[:cluster_tolerance]
          rule_type = params[:rule_type]
          fc1 = params[:fc1]
          fc2 = params[:fc2]
          rule_order = params[:rule_order]
          if rule_order.nil?
            rules_orders = saved_rules_query.maximum('value_order')
            if rules_orders.nil?
              rule_order = 1
            else
              rule_order = rules_orders + 1
            end
          else
            rule_order = rule_order.to_i
          end
          cluster_tolerance = nil if cluster_tolerance == ''
          fc1 = nil if fc1 == ''
          fc2 = nil if fc2 == ''
          saved_rule = @operation.value OperationParameter::PARAM_RULE_JSON, rule_order
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
          is_filled = true # (@operation.values OperationParameter::PARAM_RULE_JSON).count == 0
          unless class_set == '' || class_set.nil?
            rule_str = OperationsController.helpers.rule_types[rule_type.to_i] unless rule_type.nil? || rule_type == ''
            rule = {
                :class_set => class_set
            }
            rule.merge!({:cluster_tolerance => cluster_tolerance}) unless cluster_tolerance.nil?
            rule.merge!({:fc1 => fc1}) unless fc1.nil?
            rule.merge!({:rule => rule_str[:rule]}) unless rule_str.nil?
            rule.merge!({:fc2 => fc2}) unless fc2.nil?
            is_filled = rule_is_filled rule.to_json, false
            if is_filled && !params[:add_topology_rule].nil?
              rule.merge!({:added => true})
            end
            @operation.set_value rule.to_json, OperationParameter::PARAM_RULE_JSON, rule_order

            if rule[:added]
              rules = saved_rules_query
              rules.each do |saved_rule|
                sr = saved_rule.value
                unless sr.nil?
                  sr = JSON.parse sr
                  if sr['class_set'] == class_set
                    sr.merge!({:cluster_tolerance => cluster_tolerance})
                    @operation.set_value sr.to_json, OperationParameter::PARAM_RULE_JSON, saved_rule.value_order
                  end
                end
              end
            end
          end
          unless params[:template].nil? || params[:template] == '' # Добавление правил из выбранного шаблона
            added = 0
            exists = 0
            set_template = TopologyRulesSetTemplate.find_by_id params[:template]
            unless set_template.nil?
              class_sets = begin
                JSON.parse(@operation.value OperationParameter::PARAM_CLASSES)
              rescue
                []
              end
              rules_orders = saved_rules_query.maximum('value_order')
              if rules_orders.nil?
                rule_order = 1
              else
                rule_order = rules_orders + 1
              end
              saved_rules = saved_rules_query.to_a.map { |rule| JSON.parse rule.value }
              set_template.topology_rule_templates.each do |template|
                same_saved_rules = saved_rules.select do |rule|
                  rule['class_set'] == template.class_set &&
                      rule['cluster_tolerance'] == template.cluster_tolerance &&
                      rule['fc1'] == template.fc1 &&
                      rule['rule'] == template.rule &&
                      rule['fc2'] == template.fc2
                end
                if same_saved_rules.count > 0
                  exists += 1
                else
                  suitable_class_sets = class_sets.select { |cs| cs['class_set'] == template.class_set }
                  fcs = suitable_class_sets.first['fcs'] if suitable_class_sets.count > 0
                  unless fcs.nil?
                    suitable_classes = fcs.select { |fc| fc['fc'] == template.fc1 }
                    type1 = suitable_classes.first['shapeType'] if suitable_classes.count > 0
                    if type1 == template.type1
                      unless fc2.nil?
                        suitable_classes = fcs.select { |fc| fc['fc'] == template.fc2 }
                        type2 = suitable_classes.first['shapeType'] if suitable_classes.count > 0
                      end
                      if type2 == template.type2
                        rule = {
                            :class_set => template.class_set,
                            :cluster_tolerance => template.cluster_tolerance,
                            :fc1 => template.fc1,
                            :rule => template.rule,
                            :fc2 => template.fc2
                        }
                        is_filled = rule_is_filled rule.to_json, false
                        if is_filled
                          rule.merge!({:added => true})
                        end
                        @operation.set_value rule.to_json, OperationParameter::PARAM_RULE_JSON, rule_order
                        rule_order += 1
                        added += 1
                      end
                    end
                  end
                end
              end
            end
            if added > 0 # Если были добавлены правила, редактируемое надо переместить в конец
              saved_rules_query.each do |saved_rule|
                rule = JSON.parse saved_rule.value
                if rule['added'].nil?
                  @operation.set_value_order OperationParameter::PARAM_RULE_JSON, saved_rule.value_order, rule_order
                  break
                end
              end
            end
            message = nil
            message = (I18n.t 'operations.rules_added', :count => added) if added > 0
            exists_message = (I18n.t 'operations.rules_already_exist', :count => exists) if exists > 0
            message = message.nil? ? exists_message : "#{message}, #{exists_message}" unless exists_message.nil?
            not_suitable = set_template.topology_rule_templates.count - added - exists
            not_suitable_message = (I18n.t 'operations.rules_unsuitable', :count => not_suitable) if not_suitable > 0
            message = message.nil? ? not_suitable_message : "#{message}, #{not_suitable_message}" unless not_suitable_message.nil?
            flash[:success] = message
          end
          unless params[:add_topology_rule].nil?
            if is_filled
              rules_orders = saved_rules_query.maximum('value_order')
              @operation.set_value({}.to_json, OperationParameter::PARAM_RULE_JSON, (rules_orders.nil? ? 1 : rules_orders + 1))
            else
              flash[:warning] = I18n.t 'operations.finish_rule_before_add_new'
            end
          end
          unless params[:force_next_step].nil?
            rules = saved_rules_query.select('value')
            rules = rules.to_a.select { |rule| rule_is_filled rule.value }
            if rules.count > 0
              TopologyRulesSetTemplate.delete_all :operation_id => @operation.id
              unless params[:save_rules_set_as_template].nil? # Сохранение набора правил в шаблон
                set_template = TopologyRulesSetTemplate.new
                set_template.user = current_user
                set_template.operation = @operation
                set_template.name = params[:rules_set_template_name]
                set_template.save
                class_sets = begin
                  JSON.parse(@operation.value OperationParameter::PARAM_CLASSES)
                rescue
                  []
                end
                rules.each do |rule|
                  rule = JSON.parse rule.value
                  class_set = rule['class_set']
                  cluster_tolerance = rule['cluster_tolerance']
                  fc1 = rule['fc1']
                  fc2 = rule['fc2']
                  rule = rule['rule']

                  suitable_class_sets = class_sets.select { |cs| cs['class_set'] == class_set }
                  fcs = suitable_class_sets.first['fcs'] if suitable_class_sets.count > 0
                  unless fcs.nil?
                    suitable_classes = fcs.select { |fc| fc['fc'] == fc1 }
                    type1 = suitable_classes.first['shapeType'] if suitable_classes.count > 0
                    unless fc2.nil?
                      suitable_classes = fcs.select { |fc| fc['fc'] == fc2 }
                      type2 = suitable_classes.first['shapeType'] if suitable_classes.count > 0
                    end
                    unless type1.nil?
                      rule_template = TopologyRuleTemplate.new
                      rule_template.topology_rules_set_template = set_template
                      rule_template.class_set = class_set
                      rule_template.cluster_tolerance = cluster_tolerance
                      rule_template.fc1 = fc1
                      rule_template.type1 = type1
                      rule_template.rule = rule
                      rule_template.fc2 = fc2
                      rule_template.type2 = type2
                      rule_template.save
                    end
                  end
                end
              end
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
              rules = saved_rules_query.select('value')
              rules = rules.to_a.select { |rule| rule_is_filled rule.value }
              rules = rules.to_a.map { |rule| JSON.parse rule.value }
              run_op = run_operation OperationsController.validate_and_zip,
                                     {
                                         :gdb => @operation.value(OperationParameter::PARAM_UPLOADED_GDB_PATH),
                                         :rules => rules.to_json
                                     }
              job_id = run_op[:job_id]
              @operation.set_value run_op[:status], OperationParameter::PARAM_VALIDATE_JOB_STATE
              @operation.set_value job_id, OperationParameter::PARAM_VALIDATE_JOB_ID
              @operation.set_value "#{OperationsController.validate_and_zip}/jobs/#{job_id}", OperationParameter::PARAM_VALIDATE_JOB_URL
              @operation.state = Operation::STATE_STARTED
              @operation.launched = Time.zone.now
              @operation.save
              flash[:success] = I18n.t 'operations.topology_rules_accepted'
              Delayed::Job.enqueue ValidateAndZipJob.new(@operation.id)
            else
              @operation.state = Operation::STATE_RULES_CREATING
              @operation.step = 2
              @operation.save
            end
            # else
            #   Delayed::Job.enqueue ValidateAndZipJob.new(@operation.id)
          end
      end
      redirect_to @operation
    else
      flash[:danger] = I18n.t 'operations.only_owner_can_work'
      redirect_to root_url
    end
  end

  def delete_rule
    @operation = Operation.find_by_id params[:id]
    if !current_user.nil? && current_user.id == @operation.user_id
      if @operation.step == 2
        rule_order = params[:order]
        rule = @operation.value OperationParameter::PARAM_RULE_JSON, rule_order
        if rule.nil?
          flash[:warning] = I18n.t 'operations.can_not_remove_rule'
        else
          @operation.remove_value OperationParameter::PARAM_RULE_JSON, rule_order
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
    id = params[:id]
    @operation = (Operation.find_by_id id) or (not_found (t 'activerecord.models.operation.one').mb_chars.capitalize, id)
    if !current_user.nil? && current_user.id == @operation.user_id
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
      @operation.created = Time.zone.now
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
          if current_user.balance < 0 && operation.cost >= Operation::FREE_THRESHOLD
            flash[:danger] = I18n.t 'operations.sorry_balance'
            redirect_to operation
          else
            file_param_id = params[:file_param_id]
            path = operation.value file_param_id
            send_file path, :filename => 'job_result.zip', :type => 'application/zip'
          end
        else
          flash[:danger] = I18n.t 'operations.only_owner_can_download'
          redirect_to root_url
        end
      end
    end
  end

  def payment
    if current_user.nil?
      redirect_to root_url
    else
      # redirect_params = Hash.new
      # redirect_params.merge!({:operation_id => params[:operation_id]}) unless params[:operation_id].nil?
      if !params[PAYMENT_SHOW_REQUISITES].nil?
        redirect_to :controller => :operations, :action => :requisites, :operation_id => params[:operation_id] # requisites_url
      elsif !params[PAYMENT_INVOICE_REQUEST].nil?
        redirect_to :controller => :operations, :action => :invoice, :operation_id => params[:operation_id] #  invoice_url, redirect_params
      elsif !params[PAYMENT_FROM_CARD].nil?
        redirect_to :controller => :operations, :action => :pay_from_card, :operation_id => params[:operation_id] #  pay_from_card_url, redirect_params
      elsif !params[PAYMENT_FROM_BALANCE].nil?
        redirect_to :controller => :operations, :action => :pay_from_balance, :operation_id => params[:operation_id] #  pay_from_balance_url, redirect_params
      end
    end
  end

  def pay_from_card
    @operation = Operation.find_by_id params[:id]
    if !current_user.nil? && current_user.id == @operation.user_id
      if !arcgis_services_folder.nil? && (@operation.cost.nil? || @operation.cost < Operation::FREE_THRESHOLD)
        flash[:warning] = t 'operation_is_free'
        redirect_to @operation
      else
        # redirect_to "https://secure.acquiropay.com?product_id=#{@operation.id}&amount=#{@operation.cost.nil? ? 0 : @operation.cost}&cf=sandbox_pay&cb_url=#{pay_callback_url}&ok_url=#{pay_ok_url}&ko_url=#{pay_ko_url}"
      end
    else
      flash[:danger] = I18n.t 'operations.only_owner_can_work'
      redirect_to root_url
    end
  end

  def pay_from_balance
    if params[:operation_id].nil?
      flash[:warning] = I18n.t 'payment.operation_not_specified'
      redirect_to root_url
    else
      @operation = Operation.find_by_id params[:operation_id]
      if current_user.nil?
        flash[:warning] = I18n.t 'payment.must_login_for_pay'
      else
        if current_user.id == @operation.user_id
          if !arcgis_services_folder.nil? && (@operation.cost.nil? || @operation.cost == 0)
            flash[:warning] = t 'operation_is_free'
          elsif current_user.balance < @operation.cost
            flash[:warning] = t 'payment.balance_low'
          else
            @operation.state = Operation::STATE_DONE
            @operation.completed = Time.zone.now
            @operation.save
            flash[:success] = t 'payment.operation_paid'
          end
          redirect_to @operation
        else
          flash[:danger] = I18n.t 'operations.only_owner_can_work'
          redirect_to root_url
        end
      end
    end
  end

  def pay_callback
    # puts "callback parameters: #{params}"
    redirect_to root_url
  end

  def pay_ok
    # puts "pay_ok parameters: #{params}"
    if params[:recharge].to_i > 0
      Recharge.create user_id: current_user.id, date: Time.zone.now, sum: params[:recharge].to_i
      flash[:success] = I18n.t 'payment.balance_was_successfully_recharged_to', :sum => params[:recharge]
    else
      flash[:success] = I18n.t 'payment.recharge_was_emulated_successfully'
    end
    redirect_to root_url
  end

  def pay_ko
    if current_user.nil?
      redirect_to root_url
    else
      flash[:warning] = t 'payment.recharge_failure_was_emulated_successfully'
      # puts "pay_ko parameters: #{params}"
      redirect_to root_url
    end
  end

  def requisites
    if current_user.nil?
      redirect_to root_url
    end
  end

  def invoice
    if current_user.nil?
      redirect_to root_url
    else
      @operation = Operation.find_by_id params[:id]
      @tab = params[:tab]
      if request.method == 'POST'
        if @operation.nil?
          sum = params[:sum].to_f
          if sum <= 0
            flash[:danger] = I18n.t 'payment.sum_missed'
            render :invoice
            return
          end
        end
        root_with_sep = "#{Rails.root}#{File::Separator}"
        if @tab.nil? || @tab == ''
          @tab = current_user.requisites_files.count > 0 ? '1' : '2'
        end
        if @tab == '1'
          if params[:select_requisites_file].nil? || params[:select_requisites_file] == ''
            flash[:warning] = I18n.t 'payment.requisites_file_not_selected'
          else
            file = UserFile.find_by_id params[:select_requisites_file].to_i
            CommonMailer.invoice_request(current_user, @operation.nil? ? sum : @operation, file.file_path).deliver_later
            flash[:success] = I18n.t 'payment.you_will_receive_invoice_by_email'
            puts "Selected file #{root_with_sep}#{file.file_path} will be used"
          end
        elsif @tab == '2'
          requisites = params[:customer_requisites]
          if params[:save_customer_requisites] == '1'
            dir = 'user_files'
            FileUtils.mkdir_p "#{root_with_sep}#{dir}" unless File.directory? "#{root_with_sep}#{dir}"
            dir = "#{dir}#{File::Separator}#{current_user.id}"
            FileUtils.mkdir_p "#{root_with_sep}#{dir}" unless File.directory? "#{root_with_sep}#{dir}"
            dir = "#{dir}#{File::Separator}#{Time.zone.now.strftime '%y%m%d%H%M%S'}"
            FileUtils.mkdir_p "#{root_with_sep}#{dir}" unless File.directory? "#{root_with_sep}#{dir}"
            user_file = "#{dir}#{File::Separator}#{requisites.original_filename}"
            FileUtils.copy requisites.tempfile, user_file

            file = UserFile.new
            file.user = current_user
            file.file_type = UserFile::FILE_TYPE_REQUISITES
            file.file_path = user_file
            file.description = params[:requisites_file_description]
            file.save
            puts "Uploaded file #{root_with_sep}#{user_file} saved and will be used"
          else
            puts "Uploaded file #{requisites.tempfile} will be used without saving"
          end
          CommonMailer.invoice_request(current_user, @operation, nil).deliver_later
          flash[:success] = I18n.t 'payment.you_will_receive_invoice_by_email'
        end
        if @operation.nil?
          redirect_to user_root_url
        else
          redirect_to @operation
        end
      end
    end
  end

  private

  def operation_params
    params.require(:operation).permit(:operation_type_id, :created, :launched, :completed, :state, :result, :description)
  end

  def self.check_unzipping_and_preparing(operation_id)
    operation = Operation.find_by_id operation_id
    job_id = OperationValue.where('operation_id = ? and operation_parameter_id = ?', operation.id, OperationParameter::PARAM_UNZIP_JOB_ID).first
    if job_id.nil?
      operation.step = 0
      operation.save
    else
      job_uri = operation.value OperationParameter::PARAM_UNZIP_JOB_URL
      result = check_operation OperationsController.unzip_and_prepare, (operation.value OperationParameter::PARAM_UNZIP_JOB_ID), job_uri
      read_messages result, operation, OperationParameter::PARAM_UNZIP_JOB_MESSAGE, OperationParameter::PARAM_UNZIP_JOB_WARNING, OperationParameter::PARAM_UNZIP_JOB_ERROR, OperationParameter::PARAM_UNZIP_JOB_EMPTY, OperationParameter::PARAM_UNZIP_JOB_ABORT

      job_state = result['jobStatus']
      if job_state.nil?
        OperationsController::JOB_IS_STILL_RUNNING
      else
        operation.set_value job_state, OperationParameter::PARAM_UNZIP_JOB_STATE
        case job_state
          when 'esriJobSucceeded'
            operation.set_value result['results_values']['gdb'], OperationParameter::PARAM_UPLOADED_GDB_PATH
            operation.set_value result['results_values']['classes'].to_json, OperationParameter::PARAM_CLASSES
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
            cost = polygons_count + lines_count + points_count
            op_cost = case cost
                        when 0..Operation::FREE_THRESHOLD - 1
                          0
                        when Operation::FREE_THRESHOLD..999
                          10
                        when 1000..9999
                          100
                        when 10000..99999
                          1000
                        else
                          10000
                      end
            operation.cost = if Time.zone.now < (Date.new 2016, 2, 4) # Бонус до 1 апреля 2016 включительно - операции с объектами до 100 000 вершин бесплатны
                               if cost > Operation::FREE_THRESHOLD
                                 now = Time.zone.now
                                 operations = operation.user.operations.where(:launched => now - 1.day..now, :state => [Operation::STATE_DONE, Operation::STATE_STARTED]) # between ? and ? and state in (?)', now, now - 1.day, [Operation::STATE_DONE, Operation::STATE_STARTED]
                                 if operations.count < 3
                                   cost < 100000 ? 0 : 10000
                                 else
                                   op_cost
                                 end
                               end
                             else
                               op_cost
                             end
            operation.step = 2
            operation.state = Operation::STATE_RULES_CREATING
            operation.save
          when 'esriJobFailed'
            operation.step = 0
            operation.state = Operation::STATE_CREATED
            operation.save
          when 'esriJobCancelling', 'esriJobCancelled'
            operation.step = 0
            operation.state = Operation::STATE_CREATED
            operation.save
          else
            OperationsController::JOB_IS_STILL_RUNNING
        end
      end
    end
  end

  def self.check_validating_and_zipping(operation_id)
    operation = Operation.find_by_id operation_id
    job_url = operation.value OperationParameter::PARAM_VALIDATE_JOB_URL
    job_result = check_operation OperationsController.validate_and_zip, (operation.value OperationParameter::PARAM_VALIDATE_JOB_ID), job_url
    OperationsController.read_messages job_result, operation, OperationParameter::PARAM_VALIDATE_JOB_MESSAGE, OperationParameter::PARAM_VALIDATE_JOB_WARNING, OperationParameter::PARAM_VALIDATE_JOB_ERROR, OperationParameter::PARAM_VALIDATE_JOB_EMPTY, OperationParameter::PARAM_VALIDATE_JOB_ABORT

    job_state = job_result['jobStatus'] unless job_result.nil?
    if job_state.nil?
      OperationsController::JOB_IS_STILL_RUNNING
    else
      operation.set_value job_state, OperationParameter::PARAM_VALIDATE_JOB_STATE
      case job_state
        when 'esriJobSucceeded'
          operation.set_value job_result['results_values']['zip_path'], OperationParameter::PARAM_RESULT_ZIP_PATH
          operation.step = 4
          operation.state = operation.cost < Operation::FREE_THRESHOLD ? Operation::STATE_DONE : Operation::STATE_NEED_PAYMENT
          operation.completed = Time.zone.now
          operation.save
        when 'esriJobFailed'
          operation.state = Operation::STATE_FAILED
          operation.save
        when 'esriJobCancelling', 'esriJobCancelled'
          operation.state = Operation::STATE_CANCELLED
          operation.save
        else
          OperationsController::JOB_IS_STILL_RUNNING
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

  def self.check_operation(service_folder, job_id, job_uri)
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
          result_json.store param_json['paramName'], param_json['value']
        end
      end
      json.store 'results_values', result_json
    end
    json
  end

  def self.read_messages(result, operation, param_type_message, param_type_warning, param_type_error, param_type_empty, param_type_abort)
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
        operation.set_value message['description'], param_type, index
      end
    end
  end

  def self.unzip_and_prepare
    "#{OperationsController.helpers.arcgis_services_folder}/UnzipAndPrepare/GPServer/UnzipAndPrepare" unless OperationsController.helpers.arcgis_services_folder.nil?
  end

  def self.validate_and_zip
    "#{OperationsController.helpers.arcgis_services_folder}/ValidateAndZip/GPServer/ValidateAndZip" unless OperationsController.helpers.arcgis_services_folder.nil?
  end

  UnzipAndPrepareJob = Struct.new(:operation_id) do
    def perform
      result = OperationsController.check_unzipping_and_preparing operation_id
      if result == OperationsController::JOB_IS_STILL_RUNNING
        sleep 5
        Delayed::Job.enqueue UnzipAndPrepareJob.new(operation_id)
      end
    end
  end

  ValidateAndZipJob = Struct.new(:operation_id) do
    def perform
      result = OperationsController.check_validating_and_zipping operation_id
      if result == OperationsController::JOB_IS_STILL_RUNNING
        sleep 5
        Delayed::Job.enqueue ValidateAndZipJob.new(operation_id)
      end
    end
  end

end
