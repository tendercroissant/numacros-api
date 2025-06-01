require 'rails_helper'

RSpec.describe JwtService do
  let(:user) { create(:user) }
  let(:payload) { { user_id: user.id } }

  describe '.encode' do
    it 'encodes a payload into a JWT token' do
      token = JwtService.encode(payload)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3) # JWT has 3 parts
    end

    it 'adds expiration time to the payload' do
      token = JwtService.encode(payload)
      decoded = JWT.decode(token, JwtService::SECRET_KEY, true, { algorithm: 'HS256' })[0]
      expect(decoded['exp']).to be_present
      expect(decoded['exp']).to be > Time.now.to_i
    end
  end

  describe '.decode' do
    it 'decodes a valid JWT token' do
      token = JwtService.encode(payload)
      decoded = JwtService.decode(token)
      expect(decoded['user_id']).to eq(user.id)
    end

    it 'returns nil for invalid token' do
      invalid_token = 'invalid.token.here'
      expect(JwtService.decode(invalid_token)).to be_nil
    end

    it 'returns nil for expired token' do
      expired_payload = { user_id: user.id, exp: 1.hour.ago.to_i }
      expired_token = JWT.encode(expired_payload, JwtService::SECRET_KEY, 'HS256')
      expect(JwtService.decode(expired_token)).to be_nil
    end
  end

  describe '.generate_access_token' do
    it 'generates a token for a user' do
      token = JwtService.generate_access_token(user)
      decoded = JwtService.decode(token)
      expect(decoded['user_id']).to eq(user.id)
    end

    it 'sets expiration to 15 minutes from now' do
      token = JwtService.generate_access_token(user)
      decoded = JWT.decode(token, JwtService::SECRET_KEY, true, { algorithm: 'HS256' })[0]
      expected_exp = 15.minutes.from_now.to_i
      expect(decoded['exp']).to be_within(5).of(expected_exp)
    end
  end
end 