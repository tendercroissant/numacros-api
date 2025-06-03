class RenameUserTablesToRemoveUserPrefix < ActiveRecord::Migration[8.0]
  def up
    rename_table :user_profiles, :profiles
    rename_table :user_settings, :settings
    rename_table :user_weights, :weights
    rename_table :user_macronutrient_targets, :macronutrient_targets
  end

  def down
    rename_table :profiles, :user_profiles
    rename_table :settings, :user_settings
    rename_table :weights, :user_weights
    rename_table :macronutrient_targets, :user_macronutrient_targets
  end
end
