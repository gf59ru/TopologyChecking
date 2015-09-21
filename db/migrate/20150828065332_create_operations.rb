class CreateOperations < ActiveRecord::Migration
  def up
    create_table :operations do |t|
      t.integer :user_id, :null => false
      t.integer :operation_type_id, :null => false
      t.datetime :created
      t.datetime :launched
      t.datetime :completed
      t.string :state
      t.string :job_id
      t.string :result

      t.timestamps null: false
    end
  end

  def down
    drop_table :operations
  end
end
