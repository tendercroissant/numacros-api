require 'rails_helper'

RSpec.describe UserProfile, type: :model do
  describe 'factories' do
    it 'creates a valid user_profile' do
      profile = build(:user_profile)
      expect(profile).to be_valid
    end

    it 'creates a user with profile trait' do
      user = create(:user, :with_profile)
      expect(user.user_profile).to be_present
      expect(user.user_profile.name).to eq('Jane Doe')
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:birth_date) }

    describe 'minimum age requirement' do
      let(:user) { create(:user) }
      
      context 'when user is 18 or older' do
        it 'is valid' do
          profile = build(:user_profile, user: user, birth_date: 20.years.ago.to_date)
          expect(profile).to be_valid
        end
      end

      context 'when user is under 18' do
        it 'is invalid' do
          profile = build(:user_profile, user: user, birth_date: 16.years.ago.to_date)
          expect(profile).not_to be_valid
          expect(profile.errors[:birth_date]).to include('must indicate user is at least 18 years old')
        end
      end

      context 'when birth_date is exactly 18 years ago' do
        it 'is valid' do
          profile = build(:user_profile, user: user, birth_date: 18.years.ago.to_date)
          expect(profile).to be_valid
        end
      end
    end
  end
end
