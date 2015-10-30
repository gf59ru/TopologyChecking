class CreateTopologyRuleTemplates < ActiveRecord::Migration

  def up
    create_table :topology_rules_set_templates do |t|
      t.integer :user_id, :null => false
      t.integer :operation_id, :null => false
      t.string :name

      t.timestamps :null => false
    end

    create_table :topology_rule_templates do |t|
      t.integer :topology_rules_set_template_id, :null => false
      t.string :class_set, :null => false
      t.float :cluster_tolerance
      t.string :fc1, :null => false
      t.string :type1, :null => false
      t.string :rule, :null => false
      t.string :fc2
      t.string :type2

      t.timestamps :null => false
    end
  end

  def down
    drop_table :topology_rule_templates
    drop_table :topology_rules_set_templates
  end

end
