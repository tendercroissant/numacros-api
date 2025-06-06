require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password).on(:create) }
    it { should validate_length_of(:password).is_at_least(8).on(:create) }
  end

  describe 'password security' do
    it 'has secure password' do
      expect(User.ancestors).to include(ActiveModel::SecurePassword)
    end
  end

  describe '#generate_tokens' do
    let(:user) { create(:user) }

    it 'returns both access and refresh tokens' do
      tokens = user.generate_tokens
      expect(tokens).to have_key(:access_token)
      expect(tokens).to have_key(:refresh_token)
    end

    it 'generates a valid access token' do
      tokens = user.generate_tokens
      decoded_token = JwtService.decode_token(tokens[:access_token])
      expect(decoded_token['user_id']).to eq(user.id)
    end

    it 'stores refresh token digest' do
      tokens = user.generate_tokens
      user.reload
      expect(user.refresh_tokens.count).to eq(1)
      expect(user.refresh_tokens.first.token).not_to be_nil
      expect(user.refresh_tokens.first.expires_at).not_to be_nil
    end
  end

  describe '#refresh_access_token' do
    let(:user) { create(:user) }

    it 'generates a new access token' do
      new_token = user.refresh_access_token
      decoded_token = JwtService.decode_token(new_token)
      expect(decoded_token['user_id']).to eq(user.id)
    end
  end

  describe '#revoke_refresh_token' do
    let(:user) { create(:user) }

    before do
      user.generate_tokens
    end

    it 'clears refresh token data' do
      user.revoke_refresh_token
      user.reload
      expect(user.refresh_tokens.active.count).to eq(0)
      expect(user.refresh_tokens.revoked.count).to eq(1)
    end
  end
end 