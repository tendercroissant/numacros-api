require 'rails_helper'

RSpec.describe "Api::V1::Users::Settings", type: :request do
  let(:user) { create(:user) }
  let(:access_token) { JwtService.generate_access_token(user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{access_token}" } }

  describe "GET /api/v1/users/setting" do
    context "when user has settings" do
      let!(:setting) { create(:setting, user: user) }

      it "returns user settings" do
        get "/api/v1/users/setting", headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['setting']).to be_present
        expect(json_response['setting']['id']).to eq(setting.id)
        expect(json_response['setting']['unit_system']).to eq(setting.unit_system)
        expect(json_response['setting']['activity_level']).to eq(setting.activity_level)
        expect(json_response['setting']['weight_goal_type']).to eq(setting.weight_goal_type)
        expect(json_response['setting']['weight_goal_rate']).to eq(setting.weight_goal_rate.to_s)
        expect(json_response['setting']['diet_type']).to eq(setting.diet_type)
      end

      it "includes timestamps" do
        get "/api/v1/users/setting", headers: auth_headers, as: :json

        json_response = JSON.parse(response.body)
        setting_data = json_response['setting']
        
        expect(setting_data['created_at']).to be_present
        expect(setting_data['updated_at']).to be_present
      end
    end

    context "when user has no settings" do
      it "returns null settings with message" do
        get "/api/v1/users/setting", headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['setting']).to be_nil
        expect(json_response['message']).to eq("No settings found for user")
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/users/setting", as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe "PUT /api/v1/users/setting" do
    let(:valid_params) do
      {
        setting: {
          unit_system: "imperial",
          activity_level: "very_active",
          weight_goal_type: "lose_weight",
          weight_goal_rate: 1.0,
          diet_type: "keto"
        }
      }
    end

    context "when user has no existing setting" do
      it "creates a new setting" do
        expect {
          put "/api/v1/users/setting",
              params: valid_params,
              headers: auth_headers
        }.to change(Setting, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.setting.unit_system).to eq("imperial")
        expect(user.setting.activity_level).to eq("very_active")
      end
    end

    context "when user has existing setting" do
      let!(:existing_setting) { create(:setting, user: user, unit_system: :metric, activity_level: :sedentary) }

      it "updates the existing setting" do
        put "/api/v1/users/setting",
            params: valid_params,
            headers: auth_headers
        
        expect(response).to have_http_status(:ok)
        existing_setting.reload
        expect(existing_setting.unit_system).to eq("imperial")
        expect(existing_setting.activity_level).to eq("very_active")
      end

      it "includes all setting fields in response" do
        put "/api/v1/users/setting", params: valid_params, headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        setting_data = json_response['setting']
        
        expect(setting_data['id']).to be_present
        expect(setting_data['unit_system']).to eq('imperial')
        expect(setting_data['activity_level']).to eq('very_active')
        expect(setting_data['weight_goal_type']).to eq('lose_weight')
        expect(setting_data['weight_goal_rate']).to eq('1.0')
        expect(setting_data['diet_type']).to eq('keto')
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          setting: {
            unit_system: "metric",
            activity_level: "very_active",
            weight_goal_rate: -5.0  # Invalid: negative weight goal rate
          }
        }
      end

      it "returns validation errors" do
        put "/api/v1/users/setting", params: invalid_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
      end

      it "does not update the setting" do
        existing_setting = create(:setting, user: user, unit_system: :metric)
        
        put "/api/v1/users/setting", params: invalid_params, headers: auth_headers, as: :json
        
        existing_setting.reload
        expect(existing_setting.unit_system).to eq("metric") # Should remain unchanged
      end
    end

    context "with partial parameters" do
      let!(:existing_setting) { create(:setting, user: user, unit_system: :metric, activity_level: :sedentary, diet_type: :balanced) }
      let(:partial_params) do
        {
          setting: {
            activity_level: "very_active"
          }
        }
      end

      it "updates only provided fields" do
        put "/api/v1/users/setting", params: partial_params, headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        existing_setting.reload
        expect(existing_setting.activity_level).to eq("very_active")
        expect(existing_setting.unit_system).to eq("metric") # Should remain unchanged
        expect(existing_setting.diet_type).to eq("balanced") # Should remain unchanged
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        put "/api/v1/users/setting", params: valid_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end 