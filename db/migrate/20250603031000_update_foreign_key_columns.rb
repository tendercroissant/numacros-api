class UpdateForeignKeyColumns < ActiveRecord::Migration[8.0]
  def up
    # Update macronutrient_targets foreign key from user_profile_id to profile_id
    rename_column :macronutrient_targets, :user_profile_id, :profile_id
  end

  def down
    # Revert macronutrient_targets foreign key from profile_id to user_profile_id
    rename_column :macronutrient_targets, :profile_id, :user_profile_id
  end
end
