class Setting < ApplicationRecord
  self.table_name = 'settings'

  belongs_to :user

  # Enums moved from UserProfile
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
  enum :diet_type, {
    balanced: 0,
    low_carb: 1,
    keto: 2,
    high_protein: 3,
    paleo: 4,
    vegetarian: 5,
    vegan: 6,
    mediterranean: 7
  }

  # Validations
  validates :unit_system, presence: true
  validates :activity_level, presence: true
  validates :weight_goal_type, presence: true
  validates :weight_goal_rate, presence: true, numericality: true, inclusion: { in: [0.0, 0.5, 1.0, 2.0] }
  validates :diet_type, presence: true

  validate :weight_goal_rate_compatibility

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

  # Calculation methods
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

  def macro_percentages
    return nil unless diet_type.present?
    DIETARY_MACROS[diet_type]
  end

  # Macronutrient calculation methods (moved from Profile)
  def profile
    user.profile
  end

  def weight_kg
    user.current_weight_kg
  end

  def bmr
    return nil unless weight_kg.present? && profile&.height_cm.present? && profile&.age.present? && profile&.gender.present?
    
    base = 10 * weight_kg + 6.25 * profile.height_cm - 5 * profile.age
    profile.gender == 'male' ? base + 5 : base - 161
  end

  def tdee
    return nil unless bmr.present? && activity_level.present?
    bmr * ACTIVITY_MULTIPLIERS[activity_level]
  end

  def calorie_goal
    return nil unless tdee.present?
    (tdee + calorie_adjustment).round
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

  def calculate_macros_for_calories(calories)
    return nil unless calories.present? && macro_percentages.present?
    
    carbs_calories = (calories * macro_percentages[:carbs] / 100.0).round
    protein_calories = (calories * macro_percentages[:protein] / 100.0).round
    fat_calories = (calories * macro_percentages[:fat] / 100.0).round
    
    {
      calories: calories,
      carbs: {
        grams: (carbs_calories / CALORIES_PER_GRAM[:carbs]).round,
        calories: carbs_calories,
        percent: macro_percentages[:carbs]
      },
      protein: {
        grams: (protein_calories / CALORIES_PER_GRAM[:protein]).round,
        calories: protein_calories,
        percent: macro_percentages[:protein]
      },
      fat: {
        grams: (fat_calories / CALORIES_PER_GRAM[:fat]).round,
        calories: fat_calories,
        percent: macro_percentages[:fat]
      }
    }
  end

  private

  def weight_goal_rate_compatibility
    return unless weight_goal_type.present? && weight_goal_rate.present?
    
    if weight_goal_type == 'maintain_weight' && weight_goal_rate != 0.0
      errors.add(:weight_goal_rate, 'must be 0.0 when maintaining weight')
    elsif weight_goal_type != 'maintain_weight' && weight_goal_rate == 0.0
      errors.add(:weight_goal_rate, 'must be greater than 0.0 when losing weight or building muscle')
    end
  end
end 