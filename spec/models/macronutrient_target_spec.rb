require 'rails_helper'

RSpec.describe MacronutrientTarget, type: :model do
  describe 'associations' do
    it { should belong_to(:user_profile) }
  end

  describe 'validations' do
    it { should validate_presence_of(:calories) }
    it { should validate_presence_of(:carbs_grams) }
    it { should validate_presence_of(:protein_grams) }
    it { should validate_presence_of(:fat_grams) }
    
    it { should validate_numericality_of(:calories).is_greater_than(0) }
    it { should validate_numericality_of(:carbs_grams).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:protein_grams).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:fat_grams).is_greater_than_or_equal_to(0) }
  end

  describe 'factories' do
    it 'creates a valid macronutrient_target' do
      # Create profile manually to avoid lifecycle hooks
      user = create(:user)
      profile = UserProfile.create!(
        user: user,
        name: "Test User",
        birth_date: "1990-01-01",
        gender: :male,
        weight_kg: 70,
        height_cm: 175,
        unit_system: :metric,
        activity_level: :sedentary,
        weight_goal_type: :maintain_weight,
        weight_goal_rate: 0.0,
        dietary_type: :balanced
      )
      # Remove the auto-created target
      profile.macronutrient_target&.destroy
      
      target = build(:macronutrient_target, user_profile: profile)
      expect(target).to be_valid
    end

    it 'creates high_calorie variant' do
      user = create(:user)
      profile = UserProfile.create!(
        user: user,
        name: "Test User",
        birth_date: "1990-01-01",
        gender: :male,
        weight_kg: 70,
        height_cm: 175,
        unit_system: :metric,
        activity_level: :sedentary,
        weight_goal_type: :maintain_weight,
        weight_goal_rate: 0.0,
        dietary_type: :balanced
      )
      profile.macronutrient_target&.destroy
      
      target = create(:macronutrient_target, :high_calorie, user_profile: profile)
      expect(target.calories).to eq(3000)
    end

    it 'creates low_carb variant' do
      user = create(:user)
      profile = UserProfile.create!(
        user: user,
        name: "Test User",
        birth_date: "1990-01-01",
        gender: :male,
        weight_kg: 70,
        height_cm: 175,
        unit_system: :metric,
        activity_level: :sedentary,
        weight_goal_type: :maintain_weight,
        weight_goal_rate: 0.0,
        dietary_type: :balanced
      )
      profile.macronutrient_target&.destroy
      
      target = create(:macronutrient_target, :low_carb, user_profile: profile)
      expect(target.carbs_grams).to eq(50)
    end
  end

  describe '#calculated_calories' do
    it 'calculates total calories from macros' do
      target = build(:macronutrient_target, carbs_grams: 100, protein_grams: 100, fat_grams: 50)
      # 100g carbs * 4 + 100g protein * 4 + 50g fat * 9 = 400 + 400 + 450 = 1250
      expect(target.calculated_calories).to eq(1250)
    end
  end

  describe '#calories_consistent?' do
    context 'when stored calories match calculated calories' do
      it 'returns true' do
        target = build(:macronutrient_target, calories: 1250, carbs_grams: 100, protein_grams: 100, fat_grams: 50)
        expect(target.calories_consistent?).to be true
      end
    end

    context 'when stored calories are slightly off (within tolerance)' do
      it 'returns true for small differences' do
        target = build(:macronutrient_target, calories: 1252, carbs_grams: 100, protein_grams: 100, fat_grams: 50)
        expect(target.calories_consistent?).to be true
      end
    end

    context 'when stored calories are significantly different' do
      it 'returns false for large differences' do
        target = build(:macronutrient_target, calories: 1500, carbs_grams: 100, protein_grams: 100, fat_grams: 50)
        expect(target.calories_consistent?).to be false
      end
    end
  end

  describe 'database constraints' do
    it 'enforces unique user_profile constraint' do
      user = create(:user)
      profile = UserProfile.create!(
        user: user,
        name: "Test User",
        birth_date: "1990-01-01",
        gender: :male,
        weight_kg: 70,
        height_cm: 175,
        unit_system: :metric,
        activity_level: :sedentary,
        weight_goal_type: :maintain_weight,
        weight_goal_rate: 0.0,
        dietary_type: :balanced
      )
      profile.macronutrient_target&.destroy
      
      create(:macronutrient_target, user_profile: profile)
      
      expect {
        create(:macronutrient_target, user_profile: profile)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
