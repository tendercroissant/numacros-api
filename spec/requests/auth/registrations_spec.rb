require 'rails_helper'

RSpec.describe "Api::V1::Auth::Registrations", type: :request do
  describe "POST /api/v1/auth/registration" do
    let(:valid_params) do
      {
        auth_registration: {
          email: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    let(:invalid_params) do
      {
        auth_registration: {
          email: "invalid-email",
          password: "short",
          password_confirmation: "different"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post "/api/v1/auth/registration", params: valid_params, as: :json
        }.to change(User, :count).by(1)
      end

      it "creates a refresh token" do
        expect {
          post "/api/v1/auth/registration", params: valid_params, as: :json
        }.to change(RefreshToken, :count).by(1)
        
        expect(response).to have_http_status(:created)
      end

      it "returns success response with tokens" do
        post "/api/v1/auth/registration", params: valid_params, as: :json
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq('User created successfully')
        expect(json_response['user']['email']).to eq('test@example.com')
        expect(json_response['access_token']).to be_present
        expect(json_response['refresh_token']).to be_present
      end

      it "returns valid JWT access token" do
        post "/api/v1/auth/registration", params: valid_params, as: :json
        json_response = JSON.parse(response.body)
        
        decoded_token = JwtService.decode(json_response['access_token'])
        expect(decoded_token['user_id']).to eq(User.last.id)
      end
    end

    context "with invalid parameters" do
      it "does not create a user" do
        expect {
          post "/api/v1/auth/registration", params: invalid_params, as: :json
        }.not_to change(User, :count)
      end

      it "returns error response" do
        post "/api/v1/auth/registration", params: invalid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
      end
    end

    context "with existing email" do
      before { create(:user, email: "test@example.com") }

      it "returns validation error" do
        post "/api/v1/auth/registration", params: valid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include(a_string_matching(/email/i))
      end
    end
  end
end 