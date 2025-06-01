require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  subject { build(:refresh_token) }

  describe 'validations' do
    it 'requires a user' do
      refresh_token = RefreshToken.new
      expect(refresh_token).to_not be_valid
      expect(refresh_token.errors[:user]).to be_present
    end

    it { should validate_uniqueness_of(:token) }
    
    it 'auto-generates token and expires_at on creation' do
      user = create(:user)
      refresh_token = RefreshToken.new(user: user)
      expect(refresh_token.token).to be_nil
      expect(refresh_token.expires_at).to be_nil
      
      refresh_token.valid?
      
      expect(refresh_token.token).to be_present
      expect(refresh_token.expires_at).to be_present
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'callbacks' do
    it 'generates a token on creation' do
      user = create(:user)
      refresh_token = RefreshToken.new(user: user)
      refresh_token.valid?
      expect(refresh_token.token).to be_present
    end

    it 'sets expiration to 30 days from now on creation' do
      user = create(:user)
      refresh_token = RefreshToken.new(user: user)
      refresh_token.valid?
      expected_time = 30.days.from_now
      expect(refresh_token.expires_at).to be_within(1.second).of(expected_time)
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    
    describe '.valid_tokens' do
      it 'returns tokens that are not expired' do
        valid_token = create(:refresh_token, user: user, expires_at: 1.hour.from_now)
        expired_token = create(:refresh_token, user: user, expires_at: 1.hour.ago)
        
        expect(RefreshToken.valid_tokens).to include(valid_token)
        expect(RefreshToken.valid_tokens).not_to include(expired_token)
      end
    end

    describe '.expired_tokens' do
      it 'returns tokens that are expired' do
        valid_token = create(:refresh_token, user: user, expires_at: 1.hour.from_now)
        expired_token = create(:refresh_token, user: user, expires_at: 1.hour.ago)
        
        expect(RefreshToken.expired_tokens).to include(expired_token)
        expect(RefreshToken.expired_tokens).not_to include(valid_token)
      end
    end
  end

  describe '#expired?' do
    it 'returns true for expired tokens' do
      token = build(:refresh_token, expires_at: 1.hour.ago)
      expect(token.expired?).to be true
    end

    it 'returns false for valid tokens' do
      token = build(:refresh_token, expires_at: 1.hour.from_now)
      expect(token.expired?).to be false
    end
  end

  describe '.cleanup_expired' do
    it 'deletes expired tokens' do
      user = create(:user)
      expired_token = create(:refresh_token, user: user, expires_at: 1.hour.ago)
      valid_token = create(:refresh_token, user: user, expires_at: 1.hour.from_now)
      
      expect { RefreshToken.cleanup_expired }.to change { RefreshToken.count }.by(-1)
      expect(RefreshToken.exists?(expired_token.id)).to be false
      expect(RefreshToken.exists?(valid_token.id)).to be true
    end
  end
end
