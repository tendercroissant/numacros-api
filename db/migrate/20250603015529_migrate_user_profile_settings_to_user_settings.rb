class MigrateUserProfileSettingsToUserSettings < ActiveRecord::Migration[8.0]
  def up
    # Create user_settings records for all users with user_profiles
    execute <<-SQL
      INSERT INTO user_settings (
        user_id, 
        unit_system, 
        activity_level, 
        weight_goal_type, 
        weight_goal_rate, 
        diet_type,
        created_at,
        updated_at
      )
      SELECT 
        user_profiles.user_id,
        COALESCE(user_profiles.unit_system, 0),
        COALESCE(user_profiles.activity_level, 0),
        COALESCE(user_profiles.weight_goal_type, 0),
        COALESCE(user_profiles.weight_goal_rate, 0.0),
        COALESCE(user_profiles.diet_type, 0),
        NOW(),
        NOW()
      FROM user_profiles
      WHERE user_profiles.user_id IS NOT NULL
    SQL

    # Create default user_settings for users without user_profiles
    execute <<-SQL
      INSERT INTO user_settings (
        user_id, 
        unit_system, 
        activity_level, 
        weight_goal_type, 
        weight_goal_rate, 
        diet_type,
        created_at,
        updated_at
      )
      SELECT 
        users.id,
        0, -- metric
        0, -- sedentary  
        0, -- lose_weight
        0.0, -- no rate
        0, -- balanced
        NOW(),
        NOW()
      FROM users
      WHERE users.id NOT IN (SELECT user_id FROM user_profiles WHERE user_id IS NOT NULL)
    SQL
  end

  def down
    # Copy settings back to user_profiles if rolling back
    execute <<-SQL
      UPDATE user_profiles 
      SET 
        unit_system = user_settings.unit_system,
        activity_level = user_settings.activity_level,
        weight_goal_type = user_settings.weight_goal_type,
        weight_goal_rate = user_settings.weight_goal_rate,
        diet_type = user_settings.diet_type,
        updated_at = NOW()
      FROM user_settings 
      WHERE user_profiles.user_id = user_settings.user_id
    SQL

    # Remove user_settings records
    UserSetting.delete_all
  end
end
