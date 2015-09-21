class CreateOperationSteps < ActiveRecord::Migration
  def up
    create_table :operation_steps do |t|
      t.integer :operation_type_id, :null => false
      t.integer :order, :null => false
      t.string :name, :null => false
      t.string :service_folder, :null => false
      t.boolean :async
      t.boolean :multiple
      t.boolean :auto

      t.timestamps null: false
    end
    rename_column :operation_parameters, :operation_type_id, :operation_step_id
  end

  def down
    rename_column :operation_parameters, :operation_step_id, :operation_type_id
    drop_table :operation_steps
  end
end
