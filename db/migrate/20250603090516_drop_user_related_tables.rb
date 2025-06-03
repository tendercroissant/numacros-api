class DropUserRelatedTables < ActiveRecord::Migration[8.0]
  def up
    # Drop foreign keys first
    remove_foreign_key :profiles, :users if foreign_key_exists?(:profiles, :users)
    remove_foreign_key :refresh_tokens, :users if foreign_key_exists?(:refresh_tokens, :users)
    remove_foreign_key :settings, :users if foreign_key_exists?(:settings, :users)
    remove_foreign_key :weights, :users if foreign_key_exists?(:weights, :users)
    
    # Drop tables
    drop_table :weights if table_exists?(:weights)
    drop_table :settings if table_exists?(:settings)
    drop_table :refresh_tokens if table_exists?(:refresh_tokens)
    drop_table :profiles if table_exists?(:profiles)
    drop_table :users if table_exists?(:users)
  end

  def down
    # Recreate users table
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    # Recreate profiles table
    create_table :profiles do |t|
      t.bigint :user_id, null: false
      t.string :name, null: false
      t.date :birth_date, null: false
      t.timestamps
      t.integer :gender, null: false, comment: "0: male, 1: female"
      t.integer :height_cm, null: false, comment: "Height in centimeters"
    end
    add_index :profiles, :user_id

    # Recreate refresh_tokens table
    create_table :refresh_tokens do |t|
      t.bigint :user_id, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :refresh_tokens, :token, unique: true
    add_index :refresh_tokens, :user_id

    # Recreate settings table
    create_table :settings do |t|
      t.bigint :user_id, null: false
      t.integer :unit_system, default: 0, null: false
      t.integer :activity_level, default: 0, null: false
      t.integer :weight_goal_type, default: 0, null: false
      t.decimal :weight_goal_rate, precision: 3, scale: 1, default: "0.0", null: false
      t.integer :diet_type, default: 0, null: false
      t.timestamps
    end
    add_index :settings, :user_id, unique: true

    # Recreate weights table
    create_table :weights do |t|
      t.bigint :user_id, null: false
      t.float :weight_kg, null: false, comment: "Weight in kilograms"
      t.datetime :recorded_at, null: false, comment: "When the weight was recorded"
      t.timestamps
    end
    add_index :weights, :recorded_at
    add_index :weights, [:user_id, :recorded_at], name: "index_weights_on_user_and_recorded_at"
    add_index :weights, :user_id

    # Recreate foreign keys
    add_foreign_key :profiles, :users
    add_foreign_key :refresh_tokens, :users
    add_foreign_key :settings, :users
    add_foreign_key :weights, :users
  end
end
