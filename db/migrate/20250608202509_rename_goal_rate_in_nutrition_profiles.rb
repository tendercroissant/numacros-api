class RenameGoalRateInNutritionProfiles < ActiveRecord::Migration[8.0]
  def change
    rename_column :nutrition_profiles, :goal_rate_kg_per_week, :goal_rate
  end
end
