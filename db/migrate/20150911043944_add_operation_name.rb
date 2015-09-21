class AddOperationName < ActiveRecord::Migration

  def up
    add_column :operations, :description, :string
    change_column :operations, :description, :string, :null => false
  end

  def down
    remove_column :operations, :description
  end
end
