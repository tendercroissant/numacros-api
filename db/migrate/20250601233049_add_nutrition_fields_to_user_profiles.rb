class AddNutritionFieldsToUserProfiles < ActiveRecord::Migration[8.0]
  def up
    # Add columns as nullable first
    add_column :user_profiles, :weight_kg, :float, comment: "Weight in kilograms"
    add_column :user_profiles, :height_cm, :integer, comment: "Height in centimeters"
    add_column :user_profiles, :unit_system, :integer, default: 0, comment: "0: metric, 1: imperial"
    add_column :user_profiles, :activity_level, :integer, default: 0, comment: "0: sedentary (1.2), 1: lightly_active (1.375), 2: moderately_active (1.55), 3: very_active (1.725), 4: extra_active (1.9)"
    add_column :user_profiles, :weight_goal_type, :integer, default: 1, comment: "0: lose_weight, 1: maintain_weight, 2: build_muscle"
    add_column :user_profiles, :weight_goal_rate, :float, default: 0.0, comment: "Rate in pounds per week: 0.0, 0.5, 1.0, 2.0"
    
    # Set default values for existing records
    execute <<-SQL
      UPDATE user_profiles 
      SET weight_kg = 70.0, 
          height_cm = 170,
          unit_system = 0,
          activity_level = 0,
          weight_goal_type = 1,
          weight_goal_rate = 0.0
      WHERE weight_kg IS NULL OR height_cm IS NULL
    SQL
    
    # Now make the physical measurement fields required
    change_column_null :user_profiles, :weight_kg, false
    change_column_null :user_profiles, :height_cm, false
    change_column_null :user_profiles, :unit_system, false
    change_column_null :user_profiles, :activity_level, false
    change_column_null :user_profiles, :weight_goal_type, false
    change_column_null :user_profiles, :weight_goal_rate, false
    
    # Add indexes for common queries
    add_index :user_profiles, :unit_system
    add_index :user_profiles, :activity_level
    add_index :user_profiles, :weight_goal_type
  end
  
  def down
    remove_index :user_profiles, :unit_system
    remove_index :user_profiles, :activity_level
    remove_index :user_profiles, :weight_goal_type
    
    remove_column :user_profiles, :weight_kg
    remove_column :user_profiles, :height_cm
    remove_column :user_profiles, :unit_system
    remove_column :user_profiles, :activity_level
    remove_column :user_profiles, :weight_goal_type
    remove_column :user_profiles, :weight_goal_rate
  end
end
