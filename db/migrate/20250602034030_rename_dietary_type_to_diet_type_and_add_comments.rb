class RenameDietaryTypeToDietTypeAndAddComments < ActiveRecord::Migration[8.0]
  def up
    # Rename the column
    rename_column :user_profiles, :dietary_type, :diet_type
    
    # Add detailed comment explaining the diet types and their macro breakdowns
    change_column_comment :user_profiles, :diet_type, <<~COMMENT.strip
      Diet type for macro calculation: 0: balanced (40% carbs, 30% protein, 30% fat), 1: low_carb (20% carbs, 40% protein, 40% fat), 2: keto (5% carbs, 20% protein, 75% fat), 3: high_protein (30% carbs, 40% protein, 30% fat), 4: paleo (30% carbs, 35% protein, 35% fat), 5: vegetarian (50% carbs, 25% protein, 25% fat), 6: vegan (55% carbs, 25% protein, 20% fat), 7: mediterranean (40% carbs, 20% protein, 40% fat), 8: custom (uses custom_*_percent fields)
    COMMENT
  end

  def down
    # Rename back
    rename_column :user_profiles, :diet_type, :dietary_type
    change_column_comment :user_profiles, :dietary_type, nil
  end
end
