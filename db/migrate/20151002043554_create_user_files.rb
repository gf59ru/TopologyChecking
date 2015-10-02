class CreateUserFiles < ActiveRecord::Migration

  def up
    create_table :user_files do |t|
      t.integer :user_id, :null => false
      t.integer :file_type, :null => false
      t.string :file_path, :null => false
      t.string :description

      t.timestamps null: false
    end
  end

  def down
    drop_table :user_files
  end

end
