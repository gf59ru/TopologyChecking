class Operation < ActiveRecord::Base
  belongs_to :operation_type
  belongs_to :user
  has_one :topology_rules_set_template, :dependent => :delete

  validates :description, :presence => true

  def self.states_enum
    [
        STATE_CREATED,
        # STATE_PARSING,
        STATE_RULES_CREATING,
        STATE_RULES_ACCEPTING,
        STATE_STARTED,
        STATE_DONE,
        STATE_NEED_PAYMENT,
        STATE_FAILED,
        STATE_CANCELLED
    ].map do |state|
      [Operation.state_name(state), state]
    end
  end

  rails_admin do
    object_label_method :description

    list do
      field :user
      field :description
      field :state, :enum do
        enum_method :states_enum
      end
      field :cost
    end

    show do
      field :user
      field :description
      field :created
      field :launched
      field :completed
      field :step
      field :state do
        formatted_value do
          Operation.state_name(value)
        end
      end
      field :cost
    end

    edit do
      field :user do
        read_only true
      end
      field :description
      field :created do
        read_only true
      end
      field :launched do
        read_only true
      end
      field :completed do
        read_only true
      end
      field :step
      field :state, :enum do
        enum_method :states_enum
      end
      field :cost do
        read_only true
      end
    end
  end

  STATE_CREATED = 0
  # STATE_PARSING = 1
  STATE_RULES_CREATING = 10
  STATE_RULES_ACCEPTING = 11
  STATE_STARTED = 30
  STATE_DONE = 40
  STATE_NEED_PAYMENT = 41
  STATE_FAILED = 42
  STATE_CANCELLED = 43

  FREE_THRESHOLD = 10

  def self.state_name(state)
    if state.nil?
      I18n.t 'operations.state_created'
    else
      case state.to_i
        when Operation::STATE_CREATED
          I18n.t 'operations.state_created'
        when Operation::STATE_RULES_CREATING
          I18n.t 'operations.state_rules_creating'
        when Operation::STATE_RULES_ACCEPTING
          I18n.t 'operations.state_rules_accepting'
        when Operation::STATE_STARTED
          I18n.t 'operations.state_started'
        when Operation::STATE_DONE, Operation::STATE_NEED_PAYMENT
          I18n.t 'operations.state_done'
        when Operation::STATE_FAILED
          I18n.t 'operations.state_failed'
        when Operation::STATE_CANCELLED
          I18n.t 'operations.state_cancelled'
      end
    end
  end

  def state_name
    Operation.state_name(state)
  end

  def state_css_class
    if state.nil?
      'text text-info'
    else
      case state.to_i
        when Operation::STATE_CREATED, Operation::STATE_STARTED, Operation::STATE_RULES_CREATING, Operation::STATE_RULES_ACCEPTING
          'text text-info'
        when Operation::STATE_DONE
          'text text-success'
        when Operation::STATE_NEED_PAYMENT, Operation::STATE_CANCELLED
          'text text-warning'
        when Operation::STATE_FAILED
          'text text-danger'
      end
    end
  end

  def cost_description
    if !cost.nil?
      case state.to_i
        when Operation::STATE_RULES_CREATING, Operation::STATE_RULES_ACCEPTING
          cost >= Operation::FREE_THRESHOLD ? "#{cost} (#{I18n.t 'operations.preliminary'})" : (I18n.t 'free')
        when Operation::STATE_STARTED
          cost >= Operation::FREE_THRESHOLD ? "#{cost} (#{I18n.t 'operations.reserved'})" : (I18n.t 'free')
        when Operation::STATE_DONE, Operation::STATE_NEED_PAYMENT
          cost >= Operation::FREE_THRESHOLD ? cost : (I18n.t 'free')
      end
    end
  end

  def can_remove
    step.nil? || step < 3 || (!state.nil? && ([Operation::STATE_FAILED, Operation::STATE_CANCELLED].include? state.to_i))
  end

  def add_value(param_value, param_id, order = nil)
    value = OperationValue.new
    value.operation_id = id
    value.operation_parameter_id = param_id
    value.value_order = order
    value.value = param_value
    value.save
  end

  def set_value(new_value, param_id, order = nil)
    if order.nil?
      value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ?', id, param_id).first
    else
      value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ? and value_order = ?', id, param_id, order).first
    end
    if value.nil?
      add_value new_value, param_id, order
    else
      value.value = new_value
      value.save
    end
  end

  def remove_value(param_id, order = nil)
    if order.nil?
      OperationValue.delete_all ['operation_id = ? and operation_parameter_id = ?', id, param_id]
    else
      OperationValue.delete_all ['operation_id = ? and operation_parameter_id = ? and value_order = ?', id, param_id, order]
    end
  end

  def set_value_order(param_id, order, new_order)
    value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ? and value_order = ?', id, param_id, order).first
    unless value.nil?
      value.value_order = new_order
      value.save
    end
  end

  def value(param_id, order = nil)
    if order.nil?
      value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ?', id, param_id).first
    else
      value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ? and value_order = ?', id, param_id, order).first
    end
    value.value unless value.nil?
  end

  def values(param_types)
    (OperationValue.where 'operation_id = ? and operation_parameter_id in (?)', id, param_types).order 'value_order'
  end

  protected


end
