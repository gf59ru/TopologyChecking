class AddServiceFolderToOperationType < ActiveRecord::Migration
  def up
    add_column :operation_types, :service_folder, :string
    change_column :operation_types, :service_folder, :string, :null => false
  end

  def down
    remove_column :operation_types, :service_folder
  end
end
