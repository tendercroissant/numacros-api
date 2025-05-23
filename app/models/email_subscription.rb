class EmailSubscription < ApplicationRecord
  before_validation :normalize_email

  validates :email, presence: true,
                   uniqueness: true,
                   'valid_email_2/email': {
                     mx: Rails.env.production?,
                     disposable: Rails.env.production?,
                     disallow_subaddressing: true
                   }

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
