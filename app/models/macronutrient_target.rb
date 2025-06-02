class MacronutrientTarget < ApplicationRecord
  belongs_to :user_profile

  validates :calories, presence: true, numericality: { greater_than: 0 }
  validates :carbs_grams, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :protein_grams, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fat_grams, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Calculate total calories from macros for verification
  def calculated_calories
    carbs_grams * 4 + protein_grams * 4 + fat_grams * 9
  end

  # Check if stored values are consistent
  def calories_consistent?
    (calculated_calories - calories).abs <= 5 # Allow small rounding differences
  end
end
