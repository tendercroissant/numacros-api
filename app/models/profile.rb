class Profile < ApplicationRecord
  self.table_name = 'profiles'

  belongs_to :user

  # Enums - only keep gender (others moved to UserSetting)
  enum :gender, { male: 0, female: 1 }

  # Validations - only for fields that remain in UserProfile
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }, format: { with: /\A[\p{L}\s\-'.]+\z/, message: "can only contain letters, spaces, hyphens, apostrophes, and periods" }
  validates :birth_date, presence: true
  validates :gender, presence: true
  validates :height_cm, presence: true, numericality: { greater_than: 100 }

  validate :minimum_age_requirement
  validate :has_current_weight

  delegate :unit_system, :activity_level, :weight_goal_type, :weight_goal_rate, :diet_type, 
           :unit_system=, :activity_level=, :weight_goal_type=, :weight_goal_rate=, :diet_type=,
           to: :setting, allow_nil: true

  # Delegate macronutrient calculations to setting
  delegate :bmr, :tdee, :calorie_goal, :carbs_calories, :protein_calories, :fat_calories,
           :carbs_grams, :protein_grams, :fat_grams, :macronutrients, :macro_percentages,
           to: :setting, allow_nil: true

  # Weight-related methods
  def weight_kg
    user.current_weight_kg
  end

  # Age calculation - keep in Profile since it uses birth_date
  def age
    return nil unless birth_date.present?
    Date.current.year - birth_date.year
  end

  # Unit conversion helpers
  def self.pounds_to_kg(pounds)
    pounds * 0.453592
  end

  def self.kg_to_pounds(kg)
    kg * 2.20462
  end

  def self.feet_inches_to_cm(feet, inches)
    total_inches = feet * 12 + inches
    total_inches * 2.54
  end

  def self.cm_to_feet_inches(cm)
    total_inches = cm / 2.54
    feet = (total_inches / 12).floor
    inches = (total_inches % 12).round
    [feet, inches]
  end

  # Get or create user_setting for delegation
  def setting
    user.setting || user.build_setting
  end

  private

  def minimum_age_requirement
    return unless birth_date.present?
    errors.add(:birth_date, 'must indicate user is at least 18 years old') if age < 18
  end

  def has_current_weight
    unless user&.current_weight_kg.present?
      errors.add(:base, 'User must have a current weight recorded')
    end
  end
end 