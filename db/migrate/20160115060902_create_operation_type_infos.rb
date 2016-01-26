class CreateOperationTypeInfos < ActiveRecord::Migration
  def up
    create_table :operation_type_infos do |t|
      t.integer :operation_type, :null => false
      t.string :locale, :null => false
      t.string :name, :null => false
      t.string :text, :null => false

      t.timestamps null: false
    end

    add_index :operation_type_infos, [:operation_type, :locale], :unique => true
  end

  def down
    drop_table :operation_type_infos
  end
end
