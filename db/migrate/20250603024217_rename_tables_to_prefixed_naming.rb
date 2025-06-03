class RenameTablesToPrefixedNaming < ActiveRecord::Migration[8.0]
  def up
    # Rename macronutrient_targets to user_macronutrient_targets
    rename_table :macronutrient_targets, :user_macronutrient_targets
    
    # Rename weights to user_weights
    rename_table :weights, :user_weights
  end

  def down
    # Reverse the renames
    rename_table :user_macronutrient_targets, :macronutrient_targets
    rename_table :user_weights, :weights
  end
end
