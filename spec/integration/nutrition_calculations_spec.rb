require 'rails_helper'

RSpec.describe "Nutrition Calculations Integration", type: :request do
  let(:user) { create(:user) }
  let(:access_token) { JwtService.generate_access_token(user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{access_token}" } }

  describe "Complete nutrition workflow" do
    context "with metric input" do
      let(:profile_params) do
        {
          profile: {
            name: "John Doe",
            birth_date: "1990-05-15",
            gender: "male",
            weight_kg: 80.0,
            height_cm: 180,
            unit_system: "metric",
            activity_level: "moderately_active",
            weight_goal_type: "lose_weight",
            weight_goal_rate: 1.0
          }
        }
      end

      it "creates profile and calculates nutrition correctly" do
        put '/api/v1/profile', params: profile_params, headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        profile_data = json_response['user']['profile']
        calculations = profile_data['calculations']
        
        # Verify profile data is stored correctly
        expect(profile_data['weight_kg']).to eq(80.0)
        expect(profile_data['height_cm']).to eq(180)
        expect(profile_data['gender']).to eq('male')
        expect(profile_data['activity_level']).to eq('moderately_active')
        expect(profile_data['weight_goal_type']).to eq('lose_weight')
        expect(profile_data['weight_goal_rate']).to eq(1.0)
        
        # Verify calculations (allow for rounding differences)
        age = Date.current.year - 1990
        expected_bmr = 10 * 80 + 6.25 * 180 - 5 * age + 5
        expected_tdee = expected_bmr * 1.55  # moderately_active multiplier
        expected_calorie_goal = (expected_tdee - 500).round  # 1 lb/week loss
        
        expect(calculations['age']).to eq(age)
        expect(calculations['bmr']).to be_within(1).of(expected_bmr)
        expect(calculations['tdee']).to be_within(1).of(expected_tdee)
        expect(calculations['calorie_goal']).to be_within(1).of(expected_calorie_goal)
      end
    end

    context "with imperial input" do
      let(:imperial_params) do
        {
          profile: {
            name: "Jane Smith",
            birth_date: "1995-08-20",
            gender: "female",
            weight: 140,  # pounds
            height_feet: 5,
            height_inches: 6,
            unit_system: "imperial",
            activity_level: "lightly_active",
            weight_goal_type: "build_muscle",
            weight_goal_rate: 0.5
          }
        }
      end

      it "converts imperial input and calculates nutrition correctly" do
        put '/api/v1/profile', params: imperial_params, headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        profile_data = json_response['user']['profile']
        calculations = profile_data['calculations']
        
        # Verify conversions
        expected_weight_kg = 140 * 0.453592  # pounds to kg
        expected_height_cm = (5 * 12 + 6) * 2.54  # feet/inches to cm
        
        expect(profile_data['weight_kg']).to be_within(0.1).of(expected_weight_kg)
        expect(profile_data['height_cm']).to eq(expected_height_cm.round)
        expect(profile_data['unit_system']).to eq('imperial')
        
        # Verify imperial display
        imperial_display = profile_data['imperial_display']
        expect(imperial_display['weight_lbs']).to be_within(0.1).of(140.0)
        expect(imperial_display['height_feet_inches']).to eq([5, 6])
        
        # Verify calculations use converted metric values (allow for conversion precision)
        age = Date.current.year - 1995
        # Use the actual stored values for precise calculation
        stored_weight = profile_data['weight_kg']
        stored_height = profile_data['height_cm']
        expected_bmr = 10 * stored_weight + 6.25 * stored_height - 5 * age - 161  # female formula
        expected_tdee = expected_bmr * 1.375  # lightly_active multiplier
        expected_calorie_goal = (expected_tdee + 250).round  # 0.5 lb/week gain
        
        expect(calculations['age']).to eq(age)
        expect(calculations['bmr']).to be_within(3).of(expected_bmr)
        expect(calculations['tdee']).to be_within(5).of(expected_tdee)
        expect(calculations['calorie_goal']).to be_within(5).of(expected_calorie_goal)
      end
    end

    context "updating goals" do
      let!(:profile) { create(:user_profile, user: user, weight_goal_type: :maintain_weight, weight_goal_rate: 0.0) }

      it "recalculates calories when goal changes" do
        # First, get current calculations
        get '/api/v1/profile', headers: auth_headers, as: :json
        initial_response = JSON.parse(response.body)
        initial_tdee = initial_response['user']['profile']['calculations']['tdee']
        initial_calorie_goal = initial_response['user']['profile']['calculations']['calorie_goal']
        
        # Verify maintenance calories equal TDEE (within rounding)
        expect(initial_calorie_goal).to be_within(1).of(initial_tdee)
        
        # Update to weight loss goal
        put '/api/v1/profile', 
            params: { profile: { weight_goal_type: "lose_weight", weight_goal_rate: 1.0 } },
            headers: auth_headers, 
            as: :json
        
        expect(response).to have_http_status(:ok)
        updated_response = JSON.parse(response.body)
        updated_calculations = updated_response['user']['profile']['calculations']
        
        # Verify TDEE stays the same but calorie goal decreases
        expect(updated_calculations['tdee']).to be_within(1).of(initial_tdee)
        expect(updated_calculations['calorie_goal']).to be_within(1).of(initial_tdee - 500)
      end
    end
  end
end 