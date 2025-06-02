class RemoveDefaultsFromUserProfileRequiredFields < ActiveRecord::Migration[8.0]
  def up
    change_column_default :user_profiles, :unit_system, from: 0, to: nil
    change_column_default :user_profiles, :activity_level, from: 0, to: nil
    change_column_default :user_profiles, :weight_goal_type, from: 1, to: nil
    change_column_default :user_profiles, :weight_goal_rate, from: 0.0, to: nil
    change_column_default :user_profiles, :dietary_type, from: 0, to: nil
  end

  def down
    change_column_default :user_profiles, :unit_system, from: nil, to: 0
    change_column_default :user_profiles, :activity_level, from: nil, to: 0
    change_column_default :user_profiles, :weight_goal_type, from: nil, to: 1
    change_column_default :user_profiles, :weight_goal_rate, from: nil, to: 0.0
    change_column_default :user_profiles, :dietary_type, from: nil, to: 0
  end
end
