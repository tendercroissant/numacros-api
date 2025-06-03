require 'rails_helper'

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  describe "POST /api/v1/auth/session" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }
    
    let(:valid_params) do
      {
        auth_session: {
          email: "test@example.com",
          password: "password123"
        }
      }
    end

    let(:invalid_params) do
      {
        auth_session: {
          email: "test@example.com",
          password: "wrongpassword"
        }
      }
    end

    context "with valid credentials" do
      it "returns success response with tokens" do
        post "/api/v1/auth/session", params: valid_params, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq('Logged in successfully')
        expect(json_response['user']['email']).to eq('test@example.com')
        expect(json_response['access_token']).to be_present
        expect(json_response['refresh_token']).to be_present
      end

      it "creates a refresh token" do
        expect {
          post "/api/v1/auth/session", params: valid_params, as: :json
        }.to change(RefreshToken, :count).by(1)
      end

      it "returns valid JWT access token" do
        post "/api/v1/auth/session", params: valid_params, as: :json
        json_response = JSON.parse(response.body)
        
        decoded_token = JwtService.decode(json_response['access_token'])
        expect(decoded_token['user_id']).to eq(user.id)
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized response" do
        post "/api/v1/auth/session", params: invalid_params, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it "does not create a refresh token" do
        expect {
          post "/api/v1/auth/session", params: invalid_params, as: :json
        }.not_to change(RefreshToken, :count)
      end
    end

    context "with missing parameters" do
      it "returns error for missing email" do
        params = { auth_session: { password: "password123" } }
        post "/api/v1/auth/session", params: params, as: :json
        
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns error for missing password" do
        params = { auth_session: { email: "test@example.com" } }
        post "/api/v1/auth/session", params: params, as: :json
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end 