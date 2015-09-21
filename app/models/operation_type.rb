class OperationType < ActiveRecord::Base
  has_many :operation_steps, :dependent => :delete_all
  has_many :operations, :dependent => :nullify
end
