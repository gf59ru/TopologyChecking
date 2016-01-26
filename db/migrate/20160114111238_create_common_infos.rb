class CreateCommonInfos < ActiveRecord::Migration
  def up
    create_table :common_infos do |t|
      t.integer :info_type, :null => false
      t.string :locale, :null => false
      t.string :text, :null => false

      t.timestamps :null => false
    end

    add_index :common_infos, [:info_type, :locale], :unique => true
  end

  def down
    drop_table :common_infos
  end
end
