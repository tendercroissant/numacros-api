class RemoveSettingsFieldsFromUserProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_column :user_profiles, :unit_system, :integer
    remove_column :user_profiles, :activity_level, :integer
    remove_column :user_profiles, :weight_goal_type, :integer
    remove_column :user_profiles, :weight_goal_rate, :decimal
    remove_column :user_profiles, :diet_type, :integer
  end
end
