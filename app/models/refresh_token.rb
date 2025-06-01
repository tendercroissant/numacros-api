class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :valid_tokens, -> { where('expires_at > ?', Time.current) }
  scope :expired_tokens, -> { where('expires_at <= ?', Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def self.cleanup_expired
    expired_tokens.delete_all
  end

  private

  def generate_token
    self.token ||= SecureRandom.uuid
  end

  def set_expiration
    self.expires_at ||= 30.days.from_now
  end
end
