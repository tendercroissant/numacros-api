class RemoveWeightKgFromNutritionProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_column :nutrition_profiles, :weight_kg, :decimal
  end
end 