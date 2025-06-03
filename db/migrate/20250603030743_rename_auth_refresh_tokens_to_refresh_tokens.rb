class RenameAuthRefreshTokensToRefreshTokens < ActiveRecord::Migration[8.0]
  def up
    rename_table :auth_refresh_tokens, :refresh_tokens
  end

  def down
    rename_table :refresh_tokens, :auth_refresh_tokens
  end
end
