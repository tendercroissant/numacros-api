class Weight < ApplicationRecord
  belongs_to :user

  validates :weight_kg, presence: true,
                       numericality: { 
                         greater_than: 0.0, 
                         less_than: 1000.0,
                         message: "must be between 0.0 and 1000.0 kg" 
                       }
  validates :recorded_at, presence: true
  validates :user_id, uniqueness: { scope: :recorded_at, message: "can only have one weight entry per exact time" }

  validate :recorded_at_not_in_future

  # Callbacks
  after_create :update_nutrition_profile_calculations
  after_update :update_nutrition_profile_calculations

  # Scopes for efficient queries
  scope :for_user, ->(user) { where(user: user) }
  scope :recent_first, -> { order(recorded_at: :desc) }
  scope :oldest_first, -> { order(recorded_at: :asc) }
  scope :in_date_range, ->(start_date, end_date) { where(recorded_at: start_date..end_date) }
  scope :recent, ->(limit = 10) { recent_first.limit(limit) }

  # Get the most recent weight for a user
  def self.latest_for_user(user)
    for_user(user).recent_first.first
  end

  # Get weight trend (positive = gaining, negative = losing)
  def self.trend_for_user(user, days: 30)
    weights = for_user(user)
                .where(recorded_at: days.days.ago..Time.current)
                .oldest_first
                .limit(2)
    
    return nil if weights.count < 2
    
    first_weight = weights.first
    last_weight = weights.last
    
    days_diff = (last_weight.recorded_at.to_date - first_weight.recorded_at.to_date).to_i
    return nil if days_diff == 0
    
    weight_change = last_weight.weight_kg - first_weight.weight_kg
    (weight_change / days_diff * 7).round(2) # kg per week
  end

  # Get weight change from previous entry
  def weight_change_from_previous
    previous_weight = user.weights
                         .where(recorded_at: ...recorded_at)
                         .recent_first
                         .first
    
    return nil unless previous_weight
    
    weight_kg - previous_weight.weight_kg
  end

  # Get days since previous entry
  def days_since_previous
    previous_weight = user.weights
                         .where(recorded_at: ...recorded_at)
                         .recent_first
                         .first
    
    return nil unless previous_weight
    
    (recorded_at.to_date - previous_weight.recorded_at.to_date).to_i
  end

  private

  def recorded_at_not_in_future
    return unless recorded_at.present?
    
    if recorded_at > Time.current
      errors.add(:recorded_at, "cannot be in the future")
    end
  end

  def update_nutrition_profile_calculations
    # Only recalculate if this is the most recent weight entry
    latest_weight = user.weights.recent_first.first
    if latest_weight == self && user.nutrition_profile.present?
      user.nutrition_profile.recalculate_all!
    end
  end
end 