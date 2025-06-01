class UserProfile < ApplicationRecord
  belongs_to :user

  validates :birth_date, presence: true
  validate :minimum_age_requirement

  private

  def minimum_age_requirement
    return unless birth_date.present?
    
    age = Date.current.year - birth_date.year
    age -= 1 if Date.current < birth_date + age.years
    
    errors.add(:birth_date, 'must indicate user is at least 18 years old') if age < 18
  end
end
