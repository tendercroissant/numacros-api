class NutritionProfile < ApplicationRecord
  belongs_to :user
  has_one :user_profile, through: :user

  enum :activity_level, {
    sedentary: 0,      # Little to no exercise
    light: 1,          # Light exercise/sports 1-3 days/week
    moderate: 2,       # Moderate exercise/sports 3-5 days/week
    active: 3,         # Hard exercise/sports 6-7 days/week
    very_active: 4     # Very hard exercise, physical job, or training twice a day
  }

  enum :goal, {
    maintain: 0,       # Maintain current weight
    lose_weight: 1,    # Weight loss
    gain_muscle: 2     # Muscle gain (recomposition)
  }

  enum :diet_type, {
    balanced: 0,           # Balanced macronutrients (50% carbs, 25% protein, 25% fat)
    high_protein: 1,       # High protein (35% carbs, 40% protein, 25% fat)
    low_carb: 2,           # Low carbohydrate (25% carbs, 40% protein, 35% fat)
    keto: 3,               # Ketogenic (5% carbs, 25% protein, 70% fat)
    low_fat: 4,            # Low fat (60% carbs, 25% protein, 15% fat)
    mediterranean: 5,      # Mediterranean (45% carbs, 20% protein, 35% fat)
    vegetarian: 6,         # Vegetarian (55% carbs, 20% protein, 25% fat)
    vegan: 7,              # Vegan (60% carbs, 15% protein, 25% fat)
    paleo: 8,              # Paleo (30% carbs, 35% protein, 35% fat)
    custom: 9              # Custom macro targets
  }

  # Weight is now handled exclusively through weights table
  validates :activity_level, presence: true
  validates :goal, presence: true
  validates :rate, presence: true,
              numericality: { 
                greater_than_or_equal_to: 0.0,
                less_than_or_equal_to: 1.0,
                message: "must be between 0.0 and 1.0 kg per week"
              }
  validates :diet_type, presence: true

  # Validate custom macro targets when diet_type is custom
  validates :target_protein_g, :target_carbs_g, :target_fat_g,
            presence: true,
            numericality: { greater_than: 0 },
            if: :custom_diet?

  before_save :calculate_targets_if_needed
  after_update :recalculate_targets_if_changed
  
  # Custom validation to ensure we have a weight from somewhere
  validate :weight_available

  # Activity level multipliers for TDEE calculation
  ACTIVITY_MULTIPLIERS = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    active: 1.725,
    very_active: 1.9
  }.freeze

  # Get current weight from weights table (single source of truth)
  def current_weight
    return nil unless user.present?
    
    user.weights.recent_first.first&.weight_kg
  end

  # Calculate BMR using Mifflin-St Jeor equation
  def calculate_bmr
    return nil unless user_profile.present?

    age = user_profile.age
    current_weight_value = current_weight
    return nil unless age && current_weight_value

    base_bmr = if user_profile.male?
      (10 * current_weight_value) + (6.25 * user_profile.height_cm) - (5 * age) + 5
    elsif user_profile.female?
      (10 * current_weight_value) + (6.25 * user_profile.height_cm) - (5 * age) - 161
    end

    base_bmr.round
  end

  # Calculate TDEE (Total Daily Energy Expenditure)
  def calculate_tdee
    bmr = calculate_bmr
    return nil unless bmr

    multiplier = ACTIVITY_MULTIPLIERS[activity_level.to_sym]
    (bmr * multiplier).round
  end

  # Calculate target calories based on goal
  def calculate_target_calories
    tdee = calculate_tdee
    return nil unless tdee

    case goal.to_sym
    when :maintain
      tdee
    when :lose_weight
      # 1 kg fat ≈ 7700 calories
      # Rate is positive but represents deficit for weight loss
      deficit_per_day = (rate * 7700) / 7
      [tdee - deficit_per_day.round, 1200].max # Minimum 1200 calories
    when :gain_muscle
      # Rate is positive and represents surplus for muscle gain
      surplus_per_day = (rate * 7700) / 7
      tdee + surplus_per_day.round
    end
  end

  # Calculate macronutrient targets based on diet type
  def calculate_macro_targets
    target_cals = calculate_target_calories
    return {} unless target_cals

    case diet_type.to_sym
    when :balanced
      {
        protein_g: ((target_cals * 0.25) / 4).round,  # 25% protein (4 cal/g)
        carbs_g: ((target_cals * 0.50) / 4).round,    # 50% carbs (4 cal/g)
        fat_g: ((target_cals * 0.25) / 9).round       # 25% fat (9 cal/g)
      }
    when :high_protein
      {
        protein_g: ((target_cals * 0.40) / 4).round,  # 40% protein
        carbs_g: ((target_cals * 0.35) / 4).round,    # 35% carbs
        fat_g: ((target_cals * 0.25) / 9).round       # 25% fat
      }
    when :low_carb
      {
        protein_g: ((target_cals * 0.40) / 4).round,  # 40% protein
        carbs_g: ((target_cals * 0.25) / 4).round,    # 25% carbs
        fat_g: ((target_cals * 0.35) / 9).round       # 35% fat
      }
    when :keto
      {
        protein_g: ((target_cals * 0.25) / 4).round,  # 25% protein
        carbs_g: ((target_cals * 0.05) / 4).round,    # 5% carbs
        fat_g: ((target_cals * 0.70) / 9).round       # 70% fat
      }
    when :low_fat
      {
        protein_g: ((target_cals * 0.25) / 4).round,  # 25% protein
        carbs_g: ((target_cals * 0.60) / 4).round,    # 60% carbs
        fat_g: ((target_cals * 0.15) / 9).round       # 15% fat
      }
    when :mediterranean
      {
        protein_g: ((target_cals * 0.20) / 4).round,  # 20% protein
        carbs_g: ((target_cals * 0.45) / 4).round,    # 45% carbs
        fat_g: ((target_cals * 0.35) / 9).round       # 35% fat
      }
    when :vegetarian
      {
        protein_g: ((target_cals * 0.20) / 4).round,  # 20% protein
        carbs_g: ((target_cals * 0.55) / 4).round,    # 55% carbs
        fat_g: ((target_cals * 0.25) / 9).round       # 25% fat
      }
    when :vegan
      {
        protein_g: ((target_cals * 0.15) / 4).round,  # 15% protein
        carbs_g: ((target_cals * 0.60) / 4).round,    # 60% carbs
        fat_g: ((target_cals * 0.25) / 9).round       # 25% fat
      }
    when :paleo
      {
        protein_g: ((target_cals * 0.35) / 4).round,  # 35% protein
        carbs_g: ((target_cals * 0.30) / 4).round,    # 30% carbs
        fat_g: ((target_cals * 0.35) / 9).round       # 35% fat
      }
    when :custom
      {
        protein_g: target_protein_g,
        carbs_g: target_carbs_g,
        fat_g: target_fat_g
      }
    end
  end

  # Update all calculated values
  def recalculate_all!
    self.bmr = calculate_bmr
    self.tdee = calculate_tdee
    self.target_calories = calculate_target_calories
    
    unless custom_diet?
      macro_targets = calculate_macro_targets
      self.target_protein_g = macro_targets[:protein_g]
      self.target_carbs_g = macro_targets[:carbs_g]
      self.target_fat_g = macro_targets[:fat_g]
    end
    
    self.calculated_at = Time.current
    save!
  end

  # Check if targets need recalculation
  def needs_recalculation?
    calculated_at.nil? || 
    calculated_at < 1.day.ago ||
    bmr.nil? ||
    tdee.nil? ||
    target_calories.nil?
  end

  private

  def custom_diet?
    diet_type == 'custom'
  end

  def calculate_targets_if_needed
    if needs_recalculation? || targets_affecting_attributes_changed?
      self.bmr = calculate_bmr
      self.tdee = calculate_tdee
      self.target_calories = calculate_target_calories
      
      unless custom_diet?
        macro_targets = calculate_macro_targets
        self.target_protein_g = macro_targets[:protein_g] if macro_targets[:protein_g]
        self.target_carbs_g = macro_targets[:carbs_g] if macro_targets[:carbs_g]
        self.target_fat_g = macro_targets[:fat_g] if macro_targets[:fat_g]
      end
      
      self.calculated_at = Time.current
    end
  end

  def recalculate_targets_if_changed
    if saved_change_to_activity_level? || 
       saved_change_to_goal? || 
       saved_change_to_rate? ||
       saved_change_to_diet_type?
      recalculate_all!
    end
  end

  def targets_affecting_attributes_changed?
    activity_level_changed? || 
    goal_changed? || 
    rate_changed? ||
    diet_type_changed?
  end

  def weight_available
    unless current_weight.present?
      errors.add(:base, "Weight must be available either in nutrition profile or weights table")
    end
  end
end 