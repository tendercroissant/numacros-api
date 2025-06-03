class User < ApplicationRecord
  has_secure_password

  has_many :refresh_tokens, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_one :setting, dependent: :destroy
  has_many :weights, dependent: :destroy

  validates :email, presence: true,
                   uniqueness: { case_sensitive: false },
                   'valid_email_2/email': {
                     mx: Rails.env.production?,
                     disposable: Rails.env.production?,
                     disallow_subaddressing: true
                   }
  validates :password, presence: true, on: :create

  before_validation :normalize_email

  # Get the user's current weight
  def current_weight
    weights.ordered.first
  end

  # Get the user's current weight in kg, or nil if no weight recorded
  def current_weight_kg
    current_weight&.weight_kg
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
