class CreateOperationValues < ActiveRecord::Migration
  def up
    create_table :operation_values do |t|
      t.integer :operation_id, :null => false
      t.integer :operation_parameter_id, :null => false
      t.integer :value_order
      t.string :value, :null => false

      t.timestamps null: false
    end

    add_column :operations, :step, :integer
  end

  def down
    drop_table :operation_values
    remove_column :operations, :step
  end
end
