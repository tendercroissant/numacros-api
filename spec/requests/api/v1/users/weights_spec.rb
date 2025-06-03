require 'rails_helper'

RSpec.describe "Api::V1::Users::Weights", type: :request do
  let(:user) { create(:user) }
  let(:access_token) { JwtService.generate_access_token(user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{access_token}" } }

  describe "GET /api/v1/users/weights" do
    context "when user has weight entries" do
      let!(:weights) { create_list(:weight, 3, user: user) }

      it "returns all weight entries ordered by creation date" do
        get "/api/v1/users/weights", headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq('Weights retrieved successfully')
        expect(json_response['weights']).to be_an(Array)
        expect(json_response['weights'].length).to eq(3)
        expect(json_response['count']).to eq(3)
      end

      it "includes weight data fields" do
        get "/api/v1/users/weights", headers: auth_headers, as: :json

        json_response = JSON.parse(response.body)
        weight_data = json_response['weights'].first
        
        expect(weight_data['id']).to be_present
        expect(weight_data['weight_kg']).to be_present
        expect(weight_data['recorded_at']).to be_present
        expect(weight_data['created_at']).to be_present
        expect(weight_data['updated_at']).to be_present
      end
    end

    context "when user has no weight entries" do
      it "returns empty array" do
        get "/api/v1/users/weights", headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['weights']).to eq([])
        expect(json_response['count']).to eq(0)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/users/weights", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/users/weights" do
    it "creates a new weight entry" do
      expect {
        post "/api/v1/users/weights", 
             params: { weight: { weight_kg: 75.0, recorded_at: Time.current } },
             headers: auth_headers
      }.to change(Weight, :count).by(1)
      
      expect(response).to have_http_status(:created)
      weight = Weight.last
      expect(weight.weight_kg).to eq(75.0)
      expect(weight.user).to eq(user)
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          weight: {
            weight_kg: -10, # Invalid negative weight
            recorded_at: Time.current
          }
        }
      end

      it "returns validation errors" do
        post "/api/v1/users/weights", params: invalid_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq('Failed to create weight entry')
        expect(json_response['errors']).to be_present
      end

      it "does not create a weight entry" do
        expect {
          post "/api/v1/users/weights", params: invalid_params, headers: auth_headers, as: :json
        }.not_to change(Weight, :count)
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        post "/api/v1/users/weights", params: { weight: { weight_kg: 75.0, recorded_at: Time.current } }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/users/weights/:id" do
    let!(:weight) { create(:weight, user: user) }
    
    it "deletes the weight entry" do
      expect {
        delete "/api/v1/users/weights/#{weight.id}", headers: auth_headers
      }.to change(Weight, :count).by(-1)
      
      expect(response).to have_http_status(:ok)
    end

    context "when weight does not exist" do
      it "returns not found" do
        delete "/api/v1/users/weights/999999", headers: auth_headers, as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Weight entry not found')
      end
    end

    context "when weight belongs to another user" do
      let(:other_user) { create(:user) }
      let!(:other_weight) { create(:weight, user: other_user) }

      it "returns not found" do
        delete "/api/v1/users/weights/#{other_weight.id}", headers: auth_headers, as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Weight entry not found')
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        delete "/api/v1/users/weights/#{weight.id}", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/users/weights/current" do
    context "when user has weight entries" do
      let!(:older_weight) { create(:weight, user: user, created_at: 2.days.ago) }
      let!(:current_weight) { create(:weight, user: user, created_at: 1.day.ago) }

      it "returns the most recent weight entry" do
        get "/api/v1/users/weights/current", headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq('Current weight retrieved successfully')
        expect(json_response['weight']['id']).to eq(current_weight.id)
      end

      it "includes weight data fields" do
        get "/api/v1/users/weights/current", headers: auth_headers, as: :json

        json_response = JSON.parse(response.body)
        weight_data = json_response['weight']
        
        expect(weight_data['id']).to be_present
        expect(weight_data['weight_kg']).to be_present
        expect(weight_data['recorded_at']).to be_present
        expect(weight_data['created_at']).to be_present
        expect(weight_data['updated_at']).to be_present
      end
    end

    context "when user has no weight entries" do
      it "returns not found" do
        get "/api/v1/users/weights/current", headers: auth_headers, as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('No weight entries found')
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/users/weights/current", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end 