class OperationStep < ActiveRecord::Base
  belongs_to :operation_type
  has_many :operation_parameters, :dependent => :delete_all
end
