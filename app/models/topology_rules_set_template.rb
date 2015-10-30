class TopologyRulesSetTemplate < ActiveRecord::Base
  belongs_to :user
  belongs_to :operation
  has_many :topology_rule_templates, :dependent => :delete_all
end
