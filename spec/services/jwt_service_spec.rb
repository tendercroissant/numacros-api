require 'rails_helper'

RSpec.describe JwtService do
  let(:user) { create(:user) }
  let(:payload) { { user_id: user.id, exp: 15.minutes.from_now.to_i } }
  let(:token) { JWT.encode(payload, ENV['JWT_SECRET_KEY']) }

  describe '.decode_token' do
    context 'with valid token' do
      it 'decodes the token successfully' do
        decoded = described_class.decode_token(token)
        expect(decoded['user_id']).to eq(user.id)
      end
    end

    context 'with invalid token' do
      it 'returns nil for malformed token' do
        expect(described_class.decode_token('invalid_token')).to be_nil
      end

      it 'returns nil for expired token' do
        expired_payload = { user_id: user.id, exp: 1.minute.ago.to_i }
        expired_token = JWT.encode(expired_payload, ENV['JWT_SECRET_KEY'])
        expect(described_class.decode_token(expired_token)).to be_nil
      end
    end
  end

  describe '.valid_refresh_token?' do
    let(:refresh_token) { SecureRandom.hex(32) }
    let(:hashed_token) { BCrypt::Password.create(refresh_token) }

    context 'with valid refresh token' do
      before do
        user.refresh_tokens.create!(
          token: hashed_token,
          expires_at: 30.days.from_now,
          status: :active
        )
      end

      it 'returns true' do
        expect(described_class.valid_refresh_token?(user, refresh_token)).to be true
      end
    end

    context 'with invalid refresh token' do
      it 'returns false when token is invalid' do
        expect(described_class.valid_refresh_token?(user, 'invalid_token')).to be false
      end

      it 'returns false when token is expired' do
        user.refresh_tokens.create!(
          token: hashed_token,
          expires_at: 1.day.ago,
          status: :active
        )
        expect(described_class.valid_refresh_token?(user, refresh_token)).to be false
      end

      it 'returns false when no refresh token exists' do
        expect(described_class.valid_refresh_token?(user, refresh_token)).to be false
      end
    end
  end
end 