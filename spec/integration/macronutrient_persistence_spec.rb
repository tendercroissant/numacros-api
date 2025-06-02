require 'rails_helper'

RSpec.describe 'Macronutrient Persistence Integration', type: :request do
  let(:user) { create(:user) }
  let(:auth_token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{auth_token}" } }

  describe 'Profile creation with macronutrient persistence' do
    it 'automatically creates and persists macronutrient targets' do
      # Create profile via API
      profile_data = {
        profile: {
          name: "Test User",
          birth_date: "1990-05-15",
          gender: "male",
          weight_kg: 75,
          height_cm: 180,
          unit_system: "metric",
          activity_level: "moderately_active",
          weight_goal_type: "lose_weight",
          weight_goal_rate: 1.0,
          dietary_type: "balanced"
        }
      }

      put '/api/v1/profile', params: profile_data, headers: headers
      expect(response).to have_http_status(:ok)

      # Check that macronutrient target was automatically created
      user.reload
      profile = user.user_profile
      expect(profile.macronutrient_target).to be_present

      target = profile.macronutrient_target
      expect(target.calories).to be > 0
      expect(target.carbs_grams).to be > 0
      expect(target.protein_grams).to be > 0
      expect(target.fat_grams).to be > 0

      # Verify response includes persisted values
      response_data = JSON.parse(response.body)
      macronutrient_target = response_data['user']['profile']['macronutrient_target']
      
      expect(macronutrient_target).to be_present
      expect(macronutrient_target['calories']).to eq(target.calories)
      expect(macronutrient_target['carbs_grams']).to eq(target.carbs_grams)
      expect(macronutrient_target['protein_grams']).to eq(target.protein_grams)
      expect(macronutrient_target['fat_grams']).to eq(target.fat_grams)
      expect(macronutrient_target['updated_at']).to be_present
    end
  end

  describe 'Profile updates with macronutrient recalculation' do
    let!(:profile) { create(:user_profile, user: user, weight_kg: 70, weight_goal_type: :maintain_weight, weight_goal_rate: 0.0) }

    before do
      # Ensure initial target exists
      expect(profile.macronutrient_target).to be_present
    end

    it 'recalculates targets when nutrition-affecting fields change' do
      initial_calories = profile.macronutrient_target.calories
      initial_updated_at = profile.macronutrient_target.updated_at

      # Update weight goal to lose weight
      update_data = {
        profile: {
          weight_goal_type: "lose_weight",
          weight_goal_rate: 1.0
        }
      }

      sleep(0.01) # Ensure timestamp difference
      put '/api/v1/profile', params: update_data, headers: headers
      expect(response).to have_http_status(:ok)

      profile.reload
      target = profile.macronutrient_target

      # Calories should be lower due to weight loss goal
      expect(target.calories).to be < initial_calories
      expect(target.updated_at).to be > initial_updated_at

      # Response should reflect updated values
      response_data = JSON.parse(response.body)
      macronutrient_target = response_data['user']['profile']['macronutrient_target']
      expect(macronutrient_target['calories']).to eq(target.calories)
    end

    it 'recalculates macros when dietary type changes' do
      initial_carbs = profile.macronutrient_target.carbs_grams
      initial_fat = profile.macronutrient_target.fat_grams

      # Change to keto diet (low carb, high fat)
      update_data = {
        profile: {
          dietary_type: "keto"
        }
      }

      put '/api/v1/profile', params: update_data, headers: headers
      expect(response).to have_http_status(:ok)

      profile.reload
      target = profile.macronutrient_target

      # Keto should have much lower carbs and higher fat
      expect(target.carbs_grams).to be < initial_carbs
      expect(target.fat_grams).to be > initial_fat

      # Response should reflect updated macros
      response_data = JSON.parse(response.body)
      macronutrient_target = response_data['user']['profile']['macronutrient_target']
      expect(macronutrient_target['carbs_grams']).to eq(target.carbs_grams)
      expect(macronutrient_target['fat_grams']).to eq(target.fat_grams)
    end

    it 'does not recalculate when non-nutrition fields change' do
      initial_updated_at = profile.macronutrient_target.updated_at

      # Update name (non-nutrition field)
      update_data = {
        profile: {
          name: "New Name"
        }
      }

      sleep(0.01) # Ensure timestamp difference
      put '/api/v1/profile', params: update_data, headers: headers
      expect(response).to have_http_status(:ok)

      profile.reload
      # Target should not have been updated
      expect(profile.macronutrient_target.updated_at).to eq(initial_updated_at)
    end
  end

  describe 'Custom dietary type persistence' do
    let!(:profile) { create(:user_profile, user: user) }

    it 'persists custom macro percentages correctly' do
      custom_data = {
        profile: {
          dietary_type: "custom",
          custom_carbs_percent: 45.0,
          custom_protein_percent: 35.0,
          custom_fat_percent: 20.0
        }
      }

      put '/api/v1/profile', params: custom_data, headers: headers
      expect(response).to have_http_status(:ok)

      profile.reload
      target = profile.macronutrient_target

      # Check that custom percentages are reflected in the stored values
      total_calories = target.calories
      expected_carbs_calories = (total_calories * 0.45).round
      expected_protein_calories = (total_calories * 0.35).round
      expected_fat_calories = (total_calories * 0.20).round

      actual_carbs_calories = target.carbs_grams * 4
      actual_protein_calories = target.protein_grams * 4
      actual_fat_calories = target.fat_grams * 9

      # Allow for small rounding differences
      expect(actual_carbs_calories).to be_within(5).of(expected_carbs_calories)
      expect(actual_protein_calories).to be_within(5).of(expected_protein_calories)
      expect(actual_fat_calories).to be_within(5).of(expected_fat_calories)
    end
  end
end 