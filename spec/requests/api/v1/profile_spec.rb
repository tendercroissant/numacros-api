require 'rails_helper'

RSpec.describe "Api::V1::Profile", type: :request do
  let(:user) { create(:user) }
  let(:access_token) { JwtService.generate_access_token(user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{access_token}" } }

  describe "GET /api/v1/profile" do
    context "when user has no profile" do
      it "returns user with null profile" do
        get '/api/v1/profile', headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['profile']).to be_nil
      end
    end

    context "when user has a complete profile" do
      let!(:profile) { 
        create(:user_profile, :male, 
          user: user, 
          name: "John Doe", 
          birth_date: "1990-05-15",
          weight_kg: 80.0,
          height_cm: 180,
          unit_system: :metric,
          activity_level: :moderately_active,
          weight_goal_type: :lose_weight,
          weight_goal_rate: 1.0
        ) 
      }

      it "returns user with complete profile data and calculations" do
        get '/api/v1/profile', headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        profile_data = json_response['user']['profile']
        
        expect(profile_data['name']).to eq("John Doe")
        expect(profile_data['birth_date']).to eq("1990-05-15")
        expect(profile_data['gender']).to eq("male")
        expect(profile_data['weight_kg']).to eq(80.0)
        expect(profile_data['height_cm']).to eq(180)
        expect(profile_data['unit_system']).to eq("metric")
        expect(profile_data['activity_level']).to eq("moderately_active")
        expect(profile_data['weight_goal_type']).to eq("lose_weight")
        expect(profile_data['weight_goal_rate']).to eq(1.0)
        
        # Check calculations are included
        expect(profile_data['calculations']).to be_present
        expect(profile_data['calculations']['age']).to eq(Date.current.year - 1990)
        expect(profile_data['calculations']['bmr']).to be_present
        expect(profile_data['calculations']['tdee']).to be_present
        expect(profile_data['calculations']['calorie_goal']).to be_present
      end
    end

    context "when user has imperial profile" do
      let!(:profile) { 
        create(:user_profile, :female, 
          user: user,
          unit_system: :imperial,
          weight_kg: 65.0,
          height_cm: 165
        ) 
      }

      it "returns imperial display conversions" do
        get '/api/v1/profile', headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        profile_data = json_response['user']['profile']
        
        expect(profile_data['imperial_display']).to be_present
        expect(profile_data['imperial_display']['weight_lbs']).to be_within(0.1).of(143.3)
        expect(profile_data['imperial_display']['height_feet_inches']).to eq([5, 5])
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get '/api/v1/profile', as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /api/v1/profile" do
    describe "metric input" do
      let(:metric_params) do
        {
          profile: {
            name: "Jane Smith",
            birth_date: "1995-03-20",
            gender: "female",
            weight_kg: 65.0,
            height_cm: 170,
            unit_system: "metric",
            activity_level: "lightly_active",
            weight_goal_type: "lose_weight",
            weight_goal_rate: 0.5
          }
        }
      end

      context "creating new profile" do
        it "creates profile with all nutrition data" do
          expect {
            put '/api/v1/profile', params: metric_params, headers: auth_headers, as: :json
          }.to change(UserProfile, :count).by(1)

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          profile_data = json_response['user']['profile']
          
          expect(profile_data['name']).to eq("Jane Smith")
          expect(profile_data['gender']).to eq("female")
          expect(profile_data['weight_kg']).to eq(65.0)
          expect(profile_data['height_cm']).to eq(170)
          expect(profile_data['unit_system']).to eq("metric")
          expect(profile_data['activity_level']).to eq("lightly_active")
          expect(profile_data['weight_goal_type']).to eq("lose_weight")
          expect(profile_data['weight_goal_rate']).to eq(0.5)
          expect(profile_data['calculations']).to be_present
        end
      end
    end

    describe "imperial input conversion" do
      let(:imperial_params) do
        {
          profile: {
            name: "John Smith",
            birth_date: "1985-10-18",
            gender: "male",
            weight: 175,  # pounds
            height_feet: 6,
            height_inches: 0,
            unit_system: "imperial",
            activity_level: "very_active",
            weight_goal_type: "build_muscle",
            weight_goal_rate: 1.0
          }
        }
      end

      it "converts imperial inputs to metric storage" do
        put '/api/v1/profile', params: imperial_params, headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        profile_data = json_response['user']['profile']
        
        # Check conversions
        expect(profile_data['weight_kg']).to be_within(0.1).of(79.4) # 175 lbs to kg
        expect(profile_data['height_cm']).to eq(183) # 6'0" to cm
        expect(profile_data['unit_system']).to eq("imperial")
        
        # Check imperial display is included
        expect(profile_data['imperial_display']).to be_present
        expect(profile_data['imperial_display']['weight_lbs']).to be_within(0.1).of(175.0)
        expect(profile_data['imperial_display']['height_feet_inches']).to eq([6, 0])
      end
    end

    describe "validation errors" do
      context "with invalid weight goal rate for maintain weight" do
        let(:invalid_params) do
          {
            profile: {
              name: "Test User",
              birth_date: "1990-01-01",
              gender: "male",
              weight_kg: 70.0,
              height_cm: 175,
              unit_system: "metric",
              activity_level: "sedentary",
              weight_goal_type: "maintain_weight",
              weight_goal_rate: 1.0  # Should be 0.0 for maintain
            }
          }
        end

        it "returns validation error" do
          put '/api/v1/profile', params: invalid_params, headers: auth_headers, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include(a_string_matching(/must be 0.0 when maintaining weight/))
        end
      end

      context "with too young birth date" do
        let(:invalid_params) do
          {
            profile: {
              name: "Too Young",
              birth_date: "2015-01-01", # Too young
              gender: "female",
              weight_kg: 40.0,
              height_cm: 150,
              unit_system: "metric",
              activity_level: "sedentary",
              weight_goal_type: "maintain_weight",
              weight_goal_rate: 0.0
            }
          }
        end

        it "returns age validation error" do
          put '/api/v1/profile', params: invalid_params, headers: auth_headers, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include(a_string_matching(/at least 13 years old/))
        end
      end

      context "with invalid weight" do
        let(:invalid_params) do
          {
            profile: {
              name: "Test User",
              birth_date: "1990-01-01",
              gender: "male",
              weight_kg: 25.0, # Too low
              height_cm: 175,
              unit_system: "metric",
              activity_level: "sedentary",
              weight_goal_type: "maintain_weight",
              weight_goal_rate: 0.0
            }
          }
        end

        it "returns weight validation error" do
          put '/api/v1/profile', params: invalid_params, headers: auth_headers, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include(a_string_matching(/Weight kg must be greater than 30/))
        end
      end
    end

    context "updating existing profile" do
      let!(:profile) { create(:user_profile, user: user) }
      let(:update_params) do
        {
          profile: {
            weight_goal_type: "build_muscle",
            weight_goal_rate: 0.5,
            activity_level: "very_active"
          }
        }
      end

      it "updates profile fields" do
        put '/api/v1/profile', params: update_params, headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        profile.reload
        expect(profile.weight_goal_type).to eq("build_muscle")
        expect(profile.weight_goal_rate).to eq(0.5)
        expect(profile.activity_level).to eq("very_active")
      end
    end

    context "without authentication" do
      let(:valid_params) do
        {
          profile: {
            name: "Test",
            birth_date: "1990-01-01",
            gender: "male",
            weight_kg: 70.0,
            height_cm: 175,
            unit_system: "metric",
            activity_level: "sedentary",
            weight_goal_type: "maintain_weight",
            weight_goal_rate: 0.0
          }
        }
      end

      it "returns unauthorized" do
        put '/api/v1/profile', params: valid_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
