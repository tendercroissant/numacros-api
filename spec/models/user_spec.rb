require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should have_secure_password }

    it 'validates email format' do
      user = build(:user, email: 'invalid-email')
      expect(user).to_not be_valid
      expect(user.errors[:email]).to be_present
    end

    it 'accepts valid email' do
      user = build(:user, email: 'test@example.com')
      expect(user).to be_valid
    end
  end

  describe 'associations' do
    it { should have_many(:refresh_tokens).dependent(:destroy) }
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_one(:setting).dependent(:destroy) }
    it { should have_many(:weights).dependent(:destroy) }
  end

  describe 'email normalization' do
    it 'normalizes email to lowercase and strips whitespace' do
      user = create(:user, email: '  TEST@EXAMPLE.COM  ')
      expect(user.email).to eq('test@example.com')
    end
  end

  describe 'password' do
    it 'requires password on creation' do
      user = build(:user, password: nil)
      expect(user).to_not be_valid
    end

    it 'authenticates with correct password' do
      user = create(:user, password: 'password123')
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user = create(:user, password: 'password123')
      expect(user.authenticate('wrongpassword')).to be_falsey
    end
  end
end
