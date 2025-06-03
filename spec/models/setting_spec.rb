require 'rails_helper'

RSpec.describe Setting, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'enums' do
    it { should define_enum_for(:unit_system).with_values(metric: 0, imperial: 1) }
    it { should define_enum_for(:activity_level).with_values(
      sedentary: 0, lightly_active: 1, moderately_active: 2, very_active: 3, extra_active: 4
    ) }
    it { should define_enum_for(:weight_goal_type).with_values(
      lose_weight: 0, maintain_weight: 1, build_muscle: 2
    ) }
    it { should define_enum_for(:diet_type).with_values(
      balanced: 0, low_carb: 1, keto: 2, high_protein: 3, paleo: 4, vegetarian: 5, vegan: 6, mediterranean: 7
    ) }
  end

  describe 'validations' do
    subject { create(:setting) }

    it { should validate_presence_of(:unit_system) }
    it { should validate_presence_of(:activity_level) }
    it { should validate_presence_of(:weight_goal_type) }
    it { should validate_presence_of(:weight_goal_rate) }
    it { should validate_presence_of(:diet_type) }
    it { should validate_inclusion_of(:weight_goal_rate).in_array([0.0, 0.5, 1.0, 2.0]) }

    describe 'weight goal rate compatibility' do
      let(:user) { create(:user) }

      context 'when maintaining weight' do
        it 'requires rate to be 0.0' do
          setting = build(:setting, user: user, weight_goal_type: :maintain_weight, weight_goal_rate: 1.0)
          expect(setting).not_to be_valid
          expect(setting.errors[:weight_goal_rate]).to include('must be 0.0 when maintaining weight')
        end

        it 'is valid with rate 0.0' do
          setting = build(:setting, user: user, weight_goal_type: :maintain_weight, weight_goal_rate: 0.0)
          expect(setting).to be_valid
        end
      end

      context 'when losing weight' do
        it 'allows valid rates' do
          [0.5, 1.0, 2.0].each do |rate|
            setting = build(:setting, user: user, weight_goal_type: :lose_weight, weight_goal_rate: rate)
            expect(setting).to be_valid
          end
        end

        it 'rejects rate 0.0 for weight loss' do
          setting = build(:setting, user: user, weight_goal_type: :lose_weight, weight_goal_rate: 0.0)
          expect(setting).not_to be_valid
          expect(setting.errors[:weight_goal_rate]).to include('must be greater than 0.0 when losing weight or building muscle')
        end
      end

      context 'when building muscle' do
        it 'allows valid rates' do
          [0.5, 1.0].each do |rate|
            setting = build(:setting, user: user, weight_goal_type: :build_muscle, weight_goal_rate: rate)
            expect(setting).to be_valid
          end
        end

        it 'rejects rate 0.0 for muscle building' do
          setting = build(:setting, user: user, weight_goal_type: :build_muscle, weight_goal_rate: 0.0)
          expect(setting).not_to be_valid
          expect(setting.errors[:weight_goal_rate]).to include('must be greater than 0.0 when losing weight or building muscle')
        end
      end
    end
  end

  describe 'calculation methods' do
    let(:setting) { create(:setting) }

    describe '#calorie_adjustment' do
      it 'returns negative adjustment for weight loss' do
        setting.update!(weight_goal_type: :lose_weight, weight_goal_rate: 1.0)
        expect(setting.calorie_adjustment).to eq(-500)
      end

      it 'returns positive adjustment for muscle building' do
        setting.update!(weight_goal_type: :build_muscle, weight_goal_rate: 0.5)
        expect(setting.calorie_adjustment).to eq(250)
      end

      it 'returns zero adjustment for maintaining weight' do
        setting.update!(weight_goal_type: :maintain_weight, weight_goal_rate: 0.0)
        expect(setting.calorie_adjustment).to eq(0)
      end
    end

    describe '#macro_percentages' do
      context 'with balanced diet' do
        it 'returns correct percentages' do
          setting.update!(diet_type: :balanced)
          expect(setting.macro_percentages).to eq({ carbs: 40, protein: 30, fat: 30 })
        end
      end

      context 'with keto diet' do
        it 'returns correct percentages' do
          setting.update!(diet_type: :keto)
          expect(setting.macro_percentages).to eq({ carbs: 5, protein: 20, fat: 75 })
        end
      end

      context 'with high protein diet' do
        it 'returns correct percentages' do
          setting.update!(diet_type: :high_protein)
          expect(setting.macro_percentages).to eq({ carbs: 30, protein: 40, fat: 30 })
        end
      end
    end

    describe '#calculate_macros_for_calories' do
      before { setting.update!(diet_type: :balanced) } # 40/30/30

      it 'calculates macros for given calories' do
        macros = setting.calculate_macros_for_calories(2000)
        
        expect(macros[:calories]).to eq(2000)
        expect(macros[:carbs][:percent]).to eq(40)
        expect(macros[:protein][:percent]).to eq(30)
        expect(macros[:fat][:percent]).to eq(30)
        
        expect(macros[:carbs][:calories]).to eq(800)
        expect(macros[:protein][:calories]).to eq(600)
        expect(macros[:fat][:calories]).to eq(600)
        
        expect(macros[:carbs][:grams]).to eq(200)
        expect(macros[:protein][:grams]).to eq(150)
        expect(macros[:fat][:grams]).to eq(66)
      end

      it 'returns nil when diet_type is not set' do
        setting = build(:setting, diet_type: nil)
        expect(setting.calculate_macros_for_calories(2000)).to be_nil
      end
    end
  end

  describe 'macronutrient calculation methods' do
    let(:user) { create(:user) }
    let!(:profile) { create(:profile, :male, :with_weight, user: user, weight_kg: 80, birth_date: '1990-05-15', height_cm: 180) }
    let(:setting) { user.reload.setting }

    before do
      setting.update!(
        activity_level: :moderately_active,
        weight_goal_type: :maintain_weight,
        weight_goal_rate: 0.0,
        diet_type: :balanced
      )
    end

    describe '#weight_kg' do
      it 'gets current weight from user' do
        expect(setting.weight_kg).to eq(80.0)
      end
    end

    describe '#bmr' do
      it 'calculates BMR for male correctly' do
        expected_bmr = 10 * 80 + 6.25 * 180 - 5 * profile.age + 5
        expect(setting.bmr).to eq(expected_bmr)
      end

      it 'calculates BMR for female correctly' do
        female_profile = create(:profile, :female, :with_weight, user: create(:user), weight_kg: 65, birth_date: '1990-05-15', height_cm: 165)
        female_setting = female_profile.user.setting
        female_setting.update!(activity_level: :moderately_active, weight_goal_type: :maintain_weight, weight_goal_rate: 0.0, diet_type: :balanced)
        
        expected_bmr = 10 * 65 + 6.25 * 165 - 5 * female_profile.age - 161
        expect(female_setting.bmr).to eq(expected_bmr)
      end

      it 'returns nil when required data is missing' do
        user.weights.destroy_all
        expect(setting.bmr).to be_nil
      end
    end

    describe '#tdee' do
      it 'calculates TDEE correctly' do
        expected_tdee = setting.bmr * 1.55  # moderately_active multiplier
        expect(setting.tdee).to eq(expected_tdee)
      end

      it 'returns nil when BMR is nil' do
        user.weights.destroy_all
        expect(setting.tdee).to be_nil
      end
    end

    describe '#calorie_goal' do
      it 'calculates calorie goal correctly for maintenance' do
        expected_goal = setting.tdee.round
        expect(setting.calorie_goal).to eq(expected_goal)
      end

      it 'calculates calorie goal correctly for weight loss' do
        setting.update!(weight_goal_type: :lose_weight, weight_goal_rate: 1.0)
        expected_goal = (setting.tdee - 500).round
        expect(setting.calorie_goal).to eq(expected_goal)
      end

      it 'calculates calorie goal correctly for muscle building' do
        setting.update!(weight_goal_type: :build_muscle, weight_goal_rate: 0.5)
        expected_goal = (setting.tdee + 250).round
        expect(setting.calorie_goal).to eq(expected_goal)
      end
    end

    describe '#carbs_calories, #protein_calories, #fat_calories' do
      it 'calculates macro calories correctly' do
        expected_carbs_calories = (setting.calorie_goal * 0.4).round
        expected_protein_calories = (setting.calorie_goal * 0.3).round
        expected_fat_calories = (setting.calorie_goal * 0.3).round

        expect(setting.carbs_calories).to eq(expected_carbs_calories)
        expect(setting.protein_calories).to eq(expected_protein_calories)
        expect(setting.fat_calories).to eq(expected_fat_calories)
      end
    end

    describe '#carbs_grams, #protein_grams, #fat_grams' do
      it 'calculates macro grams correctly' do
        expected_carbs_grams = (setting.carbs_calories / 4).round
        expected_protein_grams = (setting.protein_calories / 4).round
        expected_fat_grams = (setting.fat_calories / 9).round

        expect(setting.carbs_grams).to eq(expected_carbs_grams)
        expect(setting.protein_grams).to eq(expected_protein_grams)
        expect(setting.fat_grams).to eq(expected_fat_grams)
      end
    end

    describe '#macronutrients' do
      it 'returns complete macronutrient breakdown' do
        macros = setting.macronutrients
        
        expect(macros[:calories]).to eq(setting.calorie_goal)
        expect(macros[:carbs][:percent]).to eq(40)
        expect(macros[:protein][:percent]).to eq(30)
        expect(macros[:fat][:percent]).to eq(30)
        
        expect(macros[:carbs][:grams]).to eq(setting.carbs_grams)
        expect(macros[:carbs][:calories]).to eq(setting.carbs_calories)
        expect(macros[:protein][:grams]).to eq(setting.protein_grams)
        expect(macros[:protein][:calories]).to eq(setting.protein_calories)
        expect(macros[:fat][:grams]).to eq(setting.fat_grams)
        expect(macros[:fat][:calories]).to eq(setting.fat_calories)
      end

      it 'returns nil when required data is missing' do
        user.weights.destroy_all
        expect(setting.macronutrients).to be_nil
      end

      context 'with different diet types' do
        it 'returns correct percentages for keto diet' do
          setting.update!(diet_type: :keto)
          macros = setting.macronutrients
          
          expect(macros[:carbs][:percent]).to eq(5)
          expect(macros[:protein][:percent]).to eq(20)
          expect(macros[:fat][:percent]).to eq(75)
        end

        it 'returns correct percentages for high protein diet' do
          setting.update!(diet_type: :high_protein)
          macros = setting.macronutrients
          
          expect(macros[:carbs][:percent]).to eq(30)
          expect(macros[:protein][:percent]).to eq(40)
          expect(macros[:fat][:percent]).to eq(30)
        end
      end
    end
  end

  describe 'constants' do
    it 'has correct activity multipliers' do
      expect(Setting::ACTIVITY_MULTIPLIERS).to eq({
        'sedentary' => 1.2,
        'lightly_active' => 1.375,
        'moderately_active' => 1.55,
        'very_active' => 1.725,
        'extra_active' => 1.9
      })
    end

    it 'has correct dietary macros' do
      expect(Setting::DIETARY_MACROS['balanced']).to eq({ carbs: 40, protein: 30, fat: 30 })
      expect(Setting::DIETARY_MACROS['keto']).to eq({ carbs: 5, protein: 20, fat: 75 })
    end

    it 'has correct calories per gram' do
      expect(Setting::CALORIES_PER_GRAM).to eq({
        carbs: 4,
        protein: 4,
        fat: 9
      })
    end
  end
end 