# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::Profile", type: :request do
  let(:user) { create(:user, :with_profile_and_weight) }
  let(:access_token) { JWT.encode({ user_id: user.id, exp: 1.hour.from_now.to_i }, Rails.application.secret_key_base) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{access_token}" } }

  describe "GET /api/v1/profile" do
    it "returns user profile with calculations" do
      get '/api/v1/profile', headers: auth_headers, as: :json
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['user']).to have_key('id')
      expect(json_response['user']).to have_key('email')
      expect(json_response['user']['profile']).to have_key('name')
      expect(json_response['user']['profile']).to have_key('calculations')
    end

    it "returns unauthorized without token" do
      get '/api/v1/profile', as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PUT /api/v1/profile" do
    let(:profile_params) do
      {
        profile: {
          activity_level: 'very_active',
          diet_type: 'high_protein',
          weight_kg: 73.5
        }
      }
    end

    it "updates profile successfully" do
      put '/api/v1/profile', params: profile_params, headers: auth_headers, as: :json
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['user']['profile']['activity_level']).to eq('very_active')
      expect(json_response['user']['profile']['diet_type']).to eq('high_protein')
    end

    it "returns validation errors for invalid data" do
      invalid_params = {
        profile: {
          birth_date: '2020-01-01'  # Too young
        }
      }
      
      put '/api/v1/profile', params: invalid_params, headers: auth_headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns unauthorized without token" do
      put '/api/v1/profile', params: profile_params, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
