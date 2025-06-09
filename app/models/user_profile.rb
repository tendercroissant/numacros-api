class UserProfile < ApplicationRecord
  belongs_to :user
  has_one :nutrition_profile, through: :user

  enum :sex, {
    male: 0,
    female: 1
  }

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :birth_date, presence: true
  validates :sex, presence: true
  validates :height_cm, presence: true, 
                       numericality: { 
                         greater_than: 50.0, 
                         less_than: 300.0,
                         message: "must be between 50.0 and 300.0 cm" 
                       }

  validate :birth_date_not_in_future
  validate :minimum_age_requirement

  # Calculate age in years
  def age
    return nil unless birth_date.present?
    
    today = Date.current
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end

  # Height in meters for calculations
  def height_m
    height_cm / 100.0
  end

  # BMI calculation using current weight
  def bmi
    current_weight = user.weights.recent_first.first&.weight_kg || nutrition_profile&.current_weight
    return nil unless current_weight.present?
    
    height_in_meters = height_m
    
    (current_weight / (height_in_meters ** 2)).round(1)
  end

  # BMI category
  def bmi_category
    bmi_value = bmi
    return nil unless bmi_value

    case bmi_value
    when 0...18.5
      :underweight
    when 18.5...25.0
      :normal
    when 25.0...30.0
      :overweight
    else
      :obese
    end
  end

  private

  def birth_date_not_in_future
    return unless birth_date.present?
    
    if birth_date > Date.current
      errors.add(:birth_date, "cannot be in the future")
    end
  end

  def minimum_age_requirement
    return unless birth_date.present?
    
    if age && age < 13
      errors.add(:birth_date, "user must be at least 13 years old")
    end
  end
end 