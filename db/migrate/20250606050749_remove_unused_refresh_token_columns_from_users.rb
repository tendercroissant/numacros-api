class RemoveUnusedRefreshTokenColumnsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :refresh_token_digest, :string
    remove_column :users, :refresh_token_expires_at, :datetime
  end
end
