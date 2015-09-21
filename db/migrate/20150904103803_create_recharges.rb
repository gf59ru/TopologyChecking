class CreateRecharges < ActiveRecord::Migration
  def up
    create_table :recharges do |t|
      t.integer :user_id, :null => false
      t.datetime :date, :null => false
      t.integer :sum, :null => false

      t.timestamps null: false
    end

    add_column :operations, :cost, :integer
  end

  def down
    drop_table :recharges
    remove_column :operations, :cost
  end
end
