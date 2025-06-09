class CreateNutritionProfilesTable < ActiveRecord::Migration[8.0]
  def change
    unless table_exists?(:nutrition_profiles)
      create_table :nutrition_profiles do |t|
        t.references :user, null: false, foreign_key: true
        t.decimal :weight_kg, precision: 5, scale: 1
        t.integer :activity_level, null: false, default: 0
        t.integer :goal, null: false, default: 0
        t.decimal :goal_rate_kg_per_week, precision: 3, scale: 1, null: false, default: 0.0
        t.integer :diet_type, null: false, default: 0
        t.integer :target_calories
        t.integer :target_protein_g
        t.integer :target_carbs_g
        t.integer :target_fat_g
        t.integer :bmr
        t.integer :tdee
        t.datetime :calculated_at
        t.integer :custom_protein_g
        t.integer :custom_carbs_g
        t.integer :custom_fat_g

        t.timestamps
      end
    end
  end
end
