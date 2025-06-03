require 'rails_helper'

RSpec.describe "Api::V1::Users::Profiles", type: :request do
  let(:user) { create(:user) }
  let(:access_token) { JwtService.generate_access_token(user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{access_token}" } }

  describe "GET /api/v1/users/profile" do
    context "when user has a profile" do
      let!(:profile) { create(:profile, user: user) }

      it "returns user profile data" do
        get "/api/v1/users/profile", headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['profile']).to be_present
        expect(json_response['user']['profile']['name']).to eq(profile.name)
        expect(json_response['user']['profile']['gender']).to eq(profile.gender)
      end

      it "includes calculated fields" do
        get "/api/v1/users/profile", headers: auth_headers, as: :json

        json_response = JSON.parse(response.body)
        profile_data = json_response['user']['profile']
        
        expect(profile_data['calculations']).to be_present
        expect(profile_data['calculations']['age']).to be_present
        expect(profile_data['calculations']['bmr']).to be_present
        expect(profile_data['calculations']['tdee']).to be_present
        expect(profile_data['calculations']['calorie_goal']).to be_present
      end

      it "includes setting fields" do
        get "/api/v1/users/profile", headers: auth_headers, as: :json

        json_response = JSON.parse(response.body)
        profile_data = json_response['user']['profile']
        
        expect(profile_data['unit_system']).to be_present
        expect(profile_data['activity_level']).to be_present
        expect(profile_data['weight_goal_type']).to be_present
        expect(profile_data['diet_type']).to be_present
      end

      it "includes macronutrients when profile is complete" do
        get "/api/v1/users/profile", headers: auth_headers, as: :json

        json_response = JSON.parse(response.body)
        profile_data = json_response['user']['profile']
        
        expect(profile_data['macronutrients']).to be_present
        expect(profile_data['macronutrients']['calories']).to be_present
        expect(profile_data['macronutrients']['carbs']['grams']).to be_present
        expect(profile_data['macronutrients']['protein']['grams']).to be_present
        expect(profile_data['macronutrients']['fat']['grams']).to be_present
      end

      context "when user prefers imperial units" do
        before do
          user.setting.update!(unit_system: 'imperial')
        end

        it "includes imperial display data" do
          get "/api/v1/users/profile", headers: auth_headers, as: :json

          json_response = JSON.parse(response.body)
          profile_data = json_response['user']['profile']
          
          expect(profile_data['imperial_display']).to be_present
          expect(profile_data['imperial_display']['weight_lbs']).to be_present
          expect(profile_data['imperial_display']['height_feet_inches']).to be_present
        end
      end
    end

    context "when user has no profile" do
      it "returns user data with null profile" do
        get "/api/v1/users/profile", headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['profile']).to be_nil
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/users/profile", as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe "PUT /api/v1/users/profile" do
    context "when user has no existing profile" do
      it "creates a new profile" do
        # Profile validation requires a current weight
        create(:weight, user: user, weight_kg: 70.0)
        
        expect {
          put "/api/v1/users/profile",
              params: { profile: { name: "John Doe", birth_date: "1990-01-01", gender: "male", height_cm: 180 } },
              headers: auth_headers
        }.to change(Profile, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.profile.name).to eq("John Doe")
      end
    end

    let(:valid_params) do
      {
        profile: {
          name: "John Doe",
          birth_date: "1990-01-01",
          gender: "male",
          height_cm: 180,
          unit_system: "metric",
          activity_level: "moderately_active",
          weight_goal_type: "maintain_weight",
          weight_goal_rate: "0.0",
          diet_type: "balanced"
        }
      }
    end

    context "with valid parameters" do
      before { create(:weight, user: user, weight_kg: 70.0) }

      it "creates a new profile when none exists" do
        expect {
          put "/api/v1/users/profile", params: valid_params, headers: auth_headers, as: :json
        }.to change(Profile, :count).by(1)
        
        expect(response).to have_http_status(:ok)
      end

      it "updates existing profile" do
        existing_profile = create(:profile, user: user, name: "Old Name")
        
        put "/api/v1/users/profile", params: valid_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:ok)
        
        existing_profile.reload
        expect(existing_profile.name).to eq("John Doe")
      end

      it "creates or updates user settings" do
        put "/api/v1/users/profile", params: valid_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:ok)
        
        user.reload
        expect(user.setting.unit_system).to eq('metric')
        expect(user.setting.activity_level).to eq('moderately_active')
      end

      it "calculates macronutrients dynamically" do
        put "/api/v1/users/profile", params: valid_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:ok)
        
        user.reload
        expect(user.profile.macronutrients).to be_present
        expect(user.profile.macronutrients[:calories]).to be > 0
      end
    end

    context "with imperial height input" do
      let(:imperial_params) do
        {
          profile: {
            name: "John Doe",
            birth_date: "1990-01-01",
            gender: "male",
            height_feet: 5,
            height_inches: 10,
            unit_system: "imperial",
            activity_level: "moderately_active",
            weight_goal_type: "maintain_weight",
            weight_goal_rate: "0.0",
            diet_type: "balanced"
          }
        }
      end

      before { create(:weight, user: user, weight_kg: 70.0) }

      it "converts imperial height to metric" do
        put "/api/v1/users/profile", params: imperial_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:ok)
        
        user.reload
        expected_height_cm = (5 * 12 + 10) * 2.54  # 5'10" to cm
        expect(user.profile.height_cm).to be_within(1).of(expected_height_cm)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          profile: {
            name: "",
            birth_date: "2010-01-01", # Too young
            gender: "male",
            height_cm: 50 # Too short
          }
        }
      end

      it "returns validation errors" do
        put "/api/v1/users/profile", params: invalid_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        put "/api/v1/users/profile", params: valid_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end 