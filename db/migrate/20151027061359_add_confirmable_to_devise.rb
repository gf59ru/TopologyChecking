class AddConfirmableToDevise < ActiveRecord::Migration

  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string # Only if using reconfirmable
    add_index :users, :confirmation_token, unique: true
    now = case connection.adapter_name.downcase.to_sym
            when :sqlite
              'datetime(\'now\')'
            else
              'NOW()'
          end
    execute "UPDATE users SET confirmed_at = #{now}"
  end

  def down
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end

end
