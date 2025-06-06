class CreateRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.integer :status, default: 0, null: false
      t.datetime :revoked_at
      t.text :revocation_reason
      t.inet :revoked_from_ip
      t.datetime :replaced_at
      t.integer :replaced_by
      t.inet :issued_from_ip
      t.text :user_agent

      t.timestamps
    end
    
    add_index :refresh_tokens, :token, unique: true
    add_index :refresh_tokens, :status
    add_index :refresh_tokens, [:user_id, :status]
    add_index :refresh_tokens, :revoked_at
    add_index :refresh_tokens, :replaced_by
  end
end
