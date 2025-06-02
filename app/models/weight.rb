class Weight < ApplicationRecord
  belongs_to :user

  validates :weight_kg, presence: true, numericality: { greater_than: 30, less_than: 500 }
  validates :recorded_at, presence: true
  validates :user_id, presence: true

  scope :ordered, -> { order(recorded_at: :desc) }
  scope :recent, -> { order(recorded_at: :desc).limit(10) }

  # Get the most recent weight for a user
  def self.current_for_user(user)
    where(user: user).ordered.first
  end

  # Get weight history for a user
  def self.history_for_user(user, limit: 30)
    where(user: user).ordered.limit(limit)
  end

  # Unit conversion helpers
  def weight_lbs
    (weight_kg * 2.20462).round(1)
  end

  def self.pounds_to_kg(pounds)
    pounds * 0.453592
  end

  def self.kg_to_pounds(kg)
    kg * 2.20462
  end
end 