class AddAuditFieldsToRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :refresh_tokens, :status, :integer, default: 0, null: false
    add_column :refresh_tokens, :revoked_at, :datetime
    add_column :refresh_tokens, :revocation_reason, :text
    add_column :refresh_tokens, :revoked_from_ip, :inet
    add_column :refresh_tokens, :replaced_at, :datetime
    add_column :refresh_tokens, :replaced_by, :integer
    add_column :refresh_tokens, :issued_from_ip, :inet
    add_column :refresh_tokens, :user_agent, :text
    
    # Add indexes for efficient querying
    add_index :refresh_tokens, :status
    add_index :refresh_tokens, [:user_id, :status]
    add_index :refresh_tokens, :revoked_at
    add_index :refresh_tokens, :replaced_by
  end
end
