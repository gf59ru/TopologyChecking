class CreateOperationTypes < ActiveRecord::Migration
  def up
    create_table :operation_types do |t|
      t.string :name, :null => false
      t.string :description

      t.timestamps null: false
    end
  end

  def down
    drop_table :operation_types
  end
end
