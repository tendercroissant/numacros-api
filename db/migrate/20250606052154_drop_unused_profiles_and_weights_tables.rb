class DropUnusedProfilesAndWeightsTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :profiles, if_exists: true
    drop_table :weights, if_exists: true
    drop_table :settings, if_exists: true
  end

  def down
    # Recreate settings table
    create_table :settings do |t|
      t.bigint :user_id, null: false
      t.integer :unit_system, default: 0, null: false
      t.integer :activity_level, default: 0, null: false
      t.integer :weight_goal_type, default: 0, null: false
      t.decimal :weight_goal_rate, precision: 3, scale: 1, default: "0.0", null: false
      t.integer :diet_type, default: 0, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:user_id], name: "index_settings_on_user_id", unique: true
    end

    # Recreate profiles table
    create_table :profiles do |t|
      t.bigint :user_id, null: false
      t.string :name, null: false
      t.date :birth_date, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :gender, null: false, comment: "0: male, 1: female"
      t.integer :height_cm, null: false, comment: "Height in centimeters"
      t.index [:user_id], name: "index_profiles_on_user_id"
    end

    # Recreate weights table
    create_table :weights do |t|
      t.bigint :user_id, null: false
      t.float :weight_kg, null: false, comment: "Weight in kilograms"
      t.datetime :recorded_at, null: false, comment: "When the weight was recorded"
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:recorded_at], name: "index_weights_on_recorded_at"
      t.index [:user_id, :recorded_at], name: "index_weights_on_user_and_recorded_at"
      t.index [:user_id], name: "index_weights_on_user_id"
    end

    # Add foreign keys
    add_foreign_key :profiles, :users
    add_foreign_key :weights, :users
    add_foreign_key :settings, :users
  end
end
