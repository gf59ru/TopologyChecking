class CreateOperationParameters < ActiveRecord::Migration
  def up
    create_table :operation_parameters do |t|
      t.integer :operation_type_id, :null => false
      t.string :name, :null => false
      t.string :description
      t.string :default_value

      t.timestamps null: false
    end
  end

  def down
    drop_table :operation_parameters
  end
end
