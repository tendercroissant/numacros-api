class DropRefreshTokens < ActiveRecord::Migration[8.0]
  def up
    drop_table :refresh_tokens
  end

  def down
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
end
