class CreateAuthRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :auth_refresh_tokens do |t|
      t.references :auth_user, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :auth_refresh_tokens, :token, unique: true
  end
end
