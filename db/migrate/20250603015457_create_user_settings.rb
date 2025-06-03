class CreateUserSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :user_settings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :unit_system, null: false, default: 0
      t.integer :activity_level, null: false, default: 0
      t.integer :weight_goal_type, null: false, default: 0
      t.decimal :weight_goal_rate, precision: 3, scale: 1, null: false, default: 0.0
      t.integer :diet_type, null: false, default: 0

      t.timestamps
    end
  end
end
