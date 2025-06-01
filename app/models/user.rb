class User < ApplicationRecord
  has_secure_password

  has_many :refresh_tokens, dependent: :destroy

  validates :email, presence: true,
                   uniqueness: { case_sensitive: false },
                   'valid_email_2/email': {
                     mx: Rails.env.production?,
                     disposable: Rails.env.production?,
                     disallow_subaddressing: true
                   }

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
