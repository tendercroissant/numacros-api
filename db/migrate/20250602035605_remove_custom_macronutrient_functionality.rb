class RemoveCustomMacronutrientFunctionality < ActiveRecord::Migration[8.0]
  def up
    # Remove custom macro percentage columns
    remove_column :user_profiles, :custom_carbs_percent, :float
    remove_column :user_profiles, :custom_protein_percent, :float
    remove_column :user_profiles, :custom_fat_percent, :float
    
    # Update the diet_type comment to remove custom option
    change_column_comment :user_profiles, :diet_type, 
      "Diet type for macro calculation: 0: balanced (40% carbs, 30% protein, 30% fat), 1: low_carb (20% carbs, 40% protein, 40% fat), 2: keto (5% carbs, 20% protein, 75% fat), 3: high_protein (30% carbs, 40% protein, 30% fat), 4: paleo (30% carbs, 35% protein, 35% fat), 5: vegetarian (50% carbs, 25% protein, 25% fat), 6: vegan (55% carbs, 25% protein, 20% fat), 7: mediterranean (40% carbs, 20% protein, 40% fat)"
    
    # Remove any existing custom diet_type values by converting them to balanced
    execute <<-SQL
      UPDATE user_profiles 
      SET diet_type = 0 
      WHERE diet_type = 8;
    SQL
  end

  def down
    # Add back custom macro percentage columns
    add_column :user_profiles, :custom_carbs_percent, :float
    add_column :user_profiles, :custom_protein_percent, :float
    add_column :user_profiles, :custom_fat_percent, :float
    
    # Restore original comment with custom option
    change_column_comment :user_profiles, :diet_type,
      "Diet type for macro calculation: 0: balanced (40% carbs, 30% protein, 30% fat), 1: low_carb (20% carbs, 40% protein, 40% fat), 2: keto (5% carbs, 20% protein, 75% fat), 3: high_protein (30% carbs, 40% protein, 30% fat), 4: paleo (30% carbs, 35% protein, 35% fat), 5: vegetarian (50% carbs, 25% protein, 25% fat), 6: vegan (55% carbs, 25% protein, 20% fat), 7: mediterranean (40% carbs, 20% protein, 40% fat), 8: custom (uses custom_*_percent fields)"
  end
end
