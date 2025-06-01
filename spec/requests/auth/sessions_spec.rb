require 'rails_helper'

RSpec.describe "Auth::Sessions", type: :request do
  describe "POST /auth/login" do
    let(:user) { create(:user, email: "test@example.com", password: "password123") }
    
    let(:valid_params) do
      {
        user: {
          email: user.email,
          password: "password123"
        }
      }
    end

    let(:invalid_params) do
      {
        user: {
          email: user.email,
          password: "wrongpassword"
        }
      }
    end

    context "with valid credentials" do
      it "returns success response with tokens" do
        post "/auth/login", params: valid_params, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq('Logged in successfully')
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['access_token']).to be_present
        expect(json_response['refresh_token']).to be_present
      end

      it "creates a refresh token" do
        expect {
          post "/auth/login", params: valid_params, as: :json
        }.to change(RefreshToken, :count).by(1)
      end

      it "returns valid JWT access token" do
        post "/auth/login", params: valid_params, as: :json
        json_response = JSON.parse(response.body)
        
        decoded_token = JwtService.decode(json_response['access_token'])
        expect(decoded_token['user_id']).to eq(user.id)
      end

      it "handles case insensitive email" do
        params = valid_params.dup
        params[:user][:email] = user.email.upcase
        
        post "/auth/login", params: params, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized for wrong password" do
        post "/auth/login", params: invalid_params, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it "returns unauthorized for non-existent user" do
        params = {
          user: {
            email: "nonexistent@example.com",
            password: "password123"
          }
        }
        
        post "/auth/login", params: params, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it "does not create refresh token on failed login" do
        expect {
          post "/auth/login", params: invalid_params, as: :json
        }.not_to change(RefreshToken, :count)
      end
    end
  end
end 