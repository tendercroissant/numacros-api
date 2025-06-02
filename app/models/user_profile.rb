class UserProfile < ApplicationRecord
  belongs_to :user
  has_one :macronutrient_target, dependent: :destroy

  # Lifecycle hooks
  after_save :calculate_and_store_macronutrients, if: :nutrition_affecting_change?

  # Enums
  enum :gender, { male: 0, female: 1 }
  enum :unit_system, { metric: 0, imperial: 1 }
  enum :activity_level, { 
    sedentary: 0,         # 1.2
    lightly_active: 1,    # 1.375
    moderately_active: 2, # 1.55
    very_active: 3,       # 1.725
    extra_active: 4       # 1.9
  }
  enum :weight_goal_type, { 
    lose_weight: 0, 
    maintain_weight: 1, 
    build_muscle: 2 
  }
  enum :dietary_type, {
    balanced: 0,
    low_carb: 1,
    keto: 2,
    high_protein: 3,
    paleo: 4,
    vegetarian: 5,
    vegan: 6,
    mediterranean: 7,
    custom: 8
  }

  # Validations
  validates :birth_date, presence: true
  validates :gender, presence: true
  validates :weight_kg, presence: true, numericality: { greater_than: 30 }
  validates :height_cm, presence: true, numericality: { greater_than: 100 }
  validates :unit_system, presence: true
  validates :activity_level, presence: true
  validates :weight_goal_type, presence: true
  validates :weight_goal_rate, presence: true, inclusion: { in: [0.0, 0.5, 1.0, 2.0] }
  validates :dietary_type, presence: true

  validate :minimum_age_requirement
  validate :weight_goal_rate_compatibility
  validate :custom_macro_percentages_when_custom

  # Activity level multipliers for TDEE calculation
  ACTIVITY_MULTIPLIERS = {
    'sedentary' => 1.2,
    'lightly_active' => 1.375,
    'moderately_active' => 1.55,
    'very_active' => 1.725,
    'extra_active' => 1.9
  }.freeze

  # Dietary type macro distributions (percentages)
  DIETARY_MACROS = {
    'balanced' => { carbs: 40, protein: 30, fat: 30 },
    'low_carb' => { carbs: 20, protein: 40, fat: 40 },
    'keto' => { carbs: 5, protein: 20, fat: 75 },
    'high_protein' => { carbs: 30, protein: 40, fat: 30 },
    'paleo' => { carbs: 30, protein: 35, fat: 35 },
    'vegetarian' => { carbs: 50, protein: 25, fat: 25 },
    'vegan' => { carbs: 55, protein: 25, fat: 20 },
    'mediterranean' => { carbs: 40, protein: 20, fat: 40 }
  }.freeze

  # Calories per gram for macronutrients
  CALORIES_PER_GRAM = {
    carbs: 4,
    protein: 4,
    fat: 9
  }.freeze

  # Calculation methods (still available for immediate calculations)
  def age
    return nil unless birth_date.present?
    Date.current.year - birth_date.year
  end

  def bmr
    return nil unless weight_kg.present? && height_cm.present? && age.present? && gender.present?
    
    base = 10 * weight_kg + 6.25 * height_cm - 5 * age
    gender == 'male' ? base + 5 : base - 161
  end

  def tdee
    return nil unless bmr.present? && activity_level.present?
    bmr * ACTIVITY_MULTIPLIERS[activity_level]
  end

  def calorie_adjustment
    return 0 unless weight_goal_type.present? && weight_goal_rate.present?
    
    case weight_goal_type
    when 'lose_weight'
      -500 * weight_goal_rate
    when 'build_muscle'
      500 * weight_goal_rate
    else
      0
    end
  end

  def calorie_goal
    return nil unless tdee.present?
    (tdee + calorie_adjustment).round
  end

  # Macronutrient calculations
  def macro_percentages
    return nil unless dietary_type.present?
    
    if dietary_type == 'custom'
      return nil unless custom_carbs_percent.present? && custom_protein_percent.present? && custom_fat_percent.present?
      {
        carbs: custom_carbs_percent,
        protein: custom_protein_percent,
        fat: custom_fat_percent
      }
    else
      DIETARY_MACROS[dietary_type]
    end
  end

  def carbs_calories
    return nil unless calorie_goal.present? && macro_percentages.present?
    (calorie_goal * macro_percentages[:carbs] / 100.0).round
  end

  def protein_calories
    return nil unless calorie_goal.present? && macro_percentages.present?
    (calorie_goal * macro_percentages[:protein] / 100.0).round
  end

  def fat_calories
    return nil unless calorie_goal.present? && macro_percentages.present?
    (calorie_goal * macro_percentages[:fat] / 100.0).round
  end

  def carbs_grams
    return nil unless carbs_calories.present?
    (carbs_calories / CALORIES_PER_GRAM[:carbs]).round
  end

  def protein_grams
    return nil unless protein_calories.present?
    (protein_calories / CALORIES_PER_GRAM[:protein]).round
  end

  def fat_grams
    return nil unless fat_calories.present?
    (fat_calories / CALORIES_PER_GRAM[:fat]).round
  end

  def macronutrients
    return nil unless calorie_goal.present? && macro_percentages.present?
    
    {
      calories: calorie_goal,
      carbs: {
        grams: carbs_grams,
        calories: carbs_calories,
        percent: macro_percentages[:carbs]
      },
      protein: {
        grams: protein_grams,
        calories: protein_calories,
        percent: macro_percentages[:protein]
      },
      fat: {
        grams: fat_grams,
        calories: fat_calories,
        percent: macro_percentages[:fat]
      }
    }
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

  private

  def minimum_age_requirement
    return unless birth_date.present?
    
    calculated_age = Date.current.year - birth_date.year
    calculated_age -= 1 if Date.current < birth_date + calculated_age.years
    
    errors.add(:birth_date, 'must indicate user is at least 13 years old') if calculated_age < 13
  end

  def weight_goal_rate_compatibility
    return unless weight_goal_type.present? && weight_goal_rate.present?

    case weight_goal_type
    when 'maintain_weight'
      errors.add(:weight_goal_rate, 'must be 0.0 when maintaining weight') unless weight_goal_rate == 0.0
    when 'lose_weight'
      unless [0.5, 1.0, 2.0].include?(weight_goal_rate)
        errors.add(:weight_goal_rate, 'must be 0.5, 1.0, or 2.0 when losing weight')
      end
    when 'build_muscle'
      unless [0.5, 1.0].include?(weight_goal_rate)
        errors.add(:weight_goal_rate, 'must be 0.5 or 1.0 when building muscle')
      end
    end
  end

  def custom_macro_percentages_when_custom
    return unless dietary_type == 'custom'
    
    unless custom_carbs_percent.present? && custom_protein_percent.present? && custom_fat_percent.present?
      errors.add(:base, 'Custom macro percentages are required when dietary type is custom')
      return
    end

    total = custom_carbs_percent + custom_protein_percent + custom_fat_percent
    unless total == 100.0
      errors.add(:base, 'Custom macro percentages must add up to 100%')
    end

    if custom_carbs_percent < 0 || custom_protein_percent < 0 || custom_fat_percent < 0
      errors.add(:base, 'Custom macro percentages must be positive')
    end
  end

  # Check if any nutrition-affecting fields changed
  def nutrition_affecting_change?
    saved_change_to_weight_kg? ||
    saved_change_to_height_cm? ||
    saved_change_to_birth_date? ||
    saved_change_to_gender? ||
    saved_change_to_activity_level? ||
    saved_change_to_weight_goal_type? ||
    saved_change_to_weight_goal_rate? ||
    saved_change_to_dietary_type? ||
    saved_change_to_custom_carbs_percent? ||
    saved_change_to_custom_protein_percent? ||
    saved_change_to_custom_fat_percent?
  end

  # Calculate and store macronutrients in the target table
  def calculate_and_store_macronutrients
    return unless profile_complete_for_calculations?

    target = macronutrient_target || build_macronutrient_target
    
    calculated_calories = calorie_goal
    calculated_carbs = carbs_grams
    calculated_protein = protein_grams
    calculated_fat = fat_grams

    return unless calculated_calories && calculated_carbs && calculated_protein && calculated_fat

    target.update!(
      calories: calculated_calories,
      carbs_grams: calculated_carbs,
      protein_grams: calculated_protein,
      fat_grams: calculated_fat
    )
  end

  # Check if profile has all required fields for calculations
  def profile_complete_for_calculations?
    weight_kg.present? && 
    height_cm.present? && 
    birth_date.present? && 
    gender.present? && 
    activity_level.present? &&
    weight_goal_type.present? &&
    weight_goal_rate.present? &&
    dietary_type.present? &&
    (dietary_type != 'custom' || (custom_carbs_percent.present? && custom_protein_percent.present? && custom_fat_percent.present?))
  end

  # For gradual migration - these fields will be required for new profiles
  def weight_kg_required?
    new_record? || weight_kg.present? || height_cm.present?
  end

  def height_cm_required?
    new_record? || weight_kg.present? || height_cm.present?
  end
end
