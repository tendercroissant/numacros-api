class RenameGoalRateToRateInNutritionProfiles < ActiveRecord::Migration[8.0]
  def change
    rename_column :nutrition_profiles, :goal_rate, :rate
  end
end
