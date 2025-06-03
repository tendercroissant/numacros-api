class RestoreRefreshTokensAndDropAuthTables < ActiveRecord::Migration[8.0]
  def up
    # Drop auth tables
    drop_table :auth_refresh_tokens
    drop_table :auth_users
    
    # Restore original refresh_tokens table
    create_table :refresh_tokens do |t|
      t.bigint :user_id, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    
    add_index :refresh_tokens, :token, unique: true
    add_index :refresh_tokens, :user_id
    add_foreign_key :refresh_tokens, :users
  end

  def down
    # Drop refresh_tokens table
    drop_table :refresh_tokens
    
    # Recreate auth tables
    create_table :auth_users do |t|
      t.string :email
      t.string :password_digest
      t.timestamps
    end
    add_index :auth_users, :email, unique: true
    
    create_table :auth_refresh_tokens do |t|
      t.bigint :auth_user_id, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :auth_refresh_tokens, :token, unique: true
    add_index :auth_refresh_tokens, :auth_user_id
    add_foreign_key :auth_refresh_tokens, :auth_users
  end
end
