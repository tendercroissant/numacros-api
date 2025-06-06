require 'rails_helper'

RSpec.describe Api::V1::AuthenticationController, type: :controller do
  describe 'POST #register' do
    let(:valid_params) do
      {
        user: {
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    let(:invalid_params) do
      {
        user: {
          email: 'invalid-email',
          password: 'short',
          password_confirmation: 'short'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post :register, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'returns tokens' do
        post :register, params: valid_params
        expect(response).to have_http_status(:created)
        expect(json_response).to have_key('tokens')
        expect(json_response['tokens']).to have_key('access_token')
        expect(json_response['tokens']).to have_key('refresh_token')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a user' do
        expect {
          post :register, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'returns validation errors' do
        post :register, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to have_key('errors')
      end
    end
  end

  describe 'POST #login' do
    let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns tokens' do
        post :login, params: { email: user.email, password: 'password123' }
        expect(response).to have_http_status(:ok)
        expect(json_response).to have_key('tokens')
        expect(json_response['tokens']).to have_key('access_token')
        expect(json_response['tokens']).to have_key('refresh_token')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized status' do
        post :login, params: { email: user.email, password: 'wrong_password' }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to have_key('error')
      end
    end
  end

  describe 'POST #refresh' do
    let(:user) { create(:user) }
    let(:tokens) { user.generate_tokens }

    before do
      request.headers['Authorization'] = "Bearer #{tokens[:access_token]}"
    end

    context 'with valid refresh token' do
      it 'returns new access token' do
        request.headers['X-Refresh-Token'] = tokens[:refresh_token]
        post :refresh
        expect(response).to have_http_status(:ok)
        expect(json_response).to have_key('access_token')
      end
    end

    context 'with invalid refresh token' do
      it 'returns unauthorized status' do
        request.headers['X-Refresh-Token'] = 'invalid_token'
        post :refresh
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to have_key('error')
      end
    end
  end

  describe 'DELETE #logout' do
    let(:user) { create(:user) }
    let(:tokens) { user.generate_tokens }

    before do
      request.headers['Authorization'] = "Bearer #{tokens[:access_token]}"
    end

    it 'revokes refresh token' do
      delete :logout
      expect(response).to have_http_status(:no_content)
      user.reload
      expect(user.refresh_tokens.active.count).to eq(0)
      expect(user.refresh_tokens.revoked.count).to eq(1)
    end
  end

  describe 'DELETE #logout_all' do
    let(:user) { create(:user) }
    let(:tokens1) { user.generate_tokens }
    let(:tokens2) { user.generate_tokens }

    before do
      # Create multiple active refresh tokens (simulating multiple devices)
      tokens1
      tokens2
      request.headers['Authorization'] = "Bearer #{tokens1[:access_token]}"
    end

    it 'revokes all refresh tokens' do
      expect(user.refresh_tokens.active.count).to eq(2)
      
      delete :logout_all
      expect(response).to have_http_status(:no_content)
      
      user.reload
      expect(user.refresh_tokens.active.count).to eq(0)
      expect(user.refresh_tokens.revoked.count).to eq(2)
    end

    it 'logs revocation reason as user_logout_all' do
      delete :logout_all
      user.reload
      
      user.refresh_tokens.revoked.each do |token|
        expect(token.revocation_reason).to eq('user_logout_all')
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end 