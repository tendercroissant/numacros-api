class RefreshToken < ApplicationRecord
  belongs_to :user
  
  enum :status, {
    active: 0,
    revoked: 1,
    expired: 2,
    replaced: 3
  }
  
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  
  scope :still_valid, -> { active.where('expires_at > ?', Time.current) }
  scope :for_audit, -> { order(created_at: :desc) }
  
  def still_valid?
    active? && expires_at > Time.current
  end
  
  def revoke!(reason: nil, ip_address: nil)
    update!(
      status: :revoked,
      revoked_at: Time.current,
      revocation_reason: reason,
      revoked_from_ip: ip_address
    )
  end
  
  def replace!(new_token)
    update!(status: :replaced, replaced_at: Time.current, replaced_by: new_token.id)
  end
  
  def self.cleanup_expired
    where('expires_at < ?', Time.current).update_all(status: :expired)
  end
end 