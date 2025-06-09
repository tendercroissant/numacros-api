require 'rails_helper'

RSpec.describe NutritionProfile, type: :model do
  describe 'associations' do
    let(:user) { create(:user) }
    before { create(:weight, user: user, weight_kg: 70.0) }
    subject { build(:nutrition_profile, user: user) }
    
    it { should belong_to(:user) }
    it { should have_one(:user_profile).through(:user) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    before { create(:weight, user: user, weight_kg: 70.0) }
    subject { build(:nutrition_profile, user: user) }
    
    it { should validate_presence_of(:activity_level) }
    it { should validate_presence_of(:goal) }
    it { should validate_presence_of(:rate) }
    it { should validate_presence_of(:diet_type) }
    
    it 'validates rate is within reasonable range' do
      profile = build(:nutrition_profile, user: user, rate: -0.5)
      expect(profile).not_to be_valid
      
      profile.rate = 3.0
      expect(profile).not_to be_valid
      expect(profile.errors[:rate]).to include('must be between 0.0 and 1.0 kg per week')
      
      profile.rate = 0.5
      expect(profile).to be_valid
    end

    context 'with custom diet type' do
      it 'validates custom macro targets are present and positive' do
        profile = build(:nutrition_profile, user: user, diet_type: :custom)
        expect(profile).not_to be_valid
        expect(profile.errors.attribute_names).to include(:target_protein_g, :target_carbs_g, :target_fat_g)
        
        profile.target_protein_g = 150
        profile.target_carbs_g = 250
        profile.target_fat_g = 80
        expect(profile).to be_valid
      end
    end

    context 'with weight available through weights table' do
      let(:user) { create(:user) }
      
      it 'is valid when user has weight entries' do
        create(:weight, user: user, weight_kg: 70.0)
        profile = build(:nutrition_profile, user: user)
        expect(profile).to be_valid
      end
    end

    it 'validates weight is available from somewhere' do
      user_without_weights = create(:user)
      profile = build(:nutrition_profile, user: user_without_weights)
      expect(profile).not_to be_valid
      expect(profile.errors[:base]).to include('Weight must be available either in nutrition profile or weights table')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:activity_level).with_values(sedentary: 0, light: 1, moderate: 2, active: 3, very_active: 4) }
    it { should define_enum_for(:goal).with_values(maintain: 0, lose_weight: 1, gain_muscle: 2) }
    it { should define_enum_for(:diet_type).with_values(balanced: 0, high_protein: 1, low_carb: 2, keto: 3, low_fat: 4, mediterranean: 5, vegetarian: 6, vegan: 7, paleo: 8, custom: 9) }
  end

  describe '#current_weight' do
    let(:user) { create(:user) }
    let(:profile) { create(:nutrition_profile, user: user) }

    context 'with weight entries' do
      it 'returns the most recent weight from weights table' do
        create(:weight, user: user, weight_kg: 70.0, recorded_at: 2.days.ago)
        create(:weight, user: user, weight_kg: 72.0, recorded_at: 1.day.ago)
        
        expect(profile.current_weight).to eq(72.0)
      end
    end

    context 'without weight entries' do
      it 'returns nil when no weights exist' do
        user_without_weights = create(:user)
        profile_without_weights = build(:nutrition_profile, user: user_without_weights)
        expect(profile_without_weights.current_weight).to be_nil
      end
    end
  end

  describe 'BMR calculations' do
    let(:user) { create(:user) }
    let(:user_profile) { create(:user_profile, user: user, birth_date: 30.years.ago, height_cm: 175.0) }
    before do 
      user_profile
      create(:weight, user: user, weight_kg: 70.0)
    end
    let(:profile) { create(:nutrition_profile, user: user) }

    context 'for male users' do
      before { user_profile.update!(sex: :male) }

      it 'calculates BMR using Mifflin-St Jeor equation' do
        bmr = profile.calculate_bmr
        # BMR = (10 * 70) + (6.25 * 175) - (5 * 30) + 5 = 700 + 1093.75 - 150 + 5 = 1648.75
        expect(bmr).to eq(1649)
      end
    end

    context 'for female users' do
      before { user_profile.update!(sex: :female) }

      it 'calculates BMR using Mifflin-St Jeor equation' do
        bmr = profile.calculate_bmr
        # BMR = (10 * 70) + (6.25 * 175) - (5 * 30) - 161 = 700 + 1093.75 - 150 - 161 = 1482.75
        expect(bmr).to eq(1483)
      end
    end


  end

  describe 'TDEE calculations' do
    let(:user) { create(:user) }
    let(:user_profile) { create(:user_profile, user: user, birth_date: 30.years.ago, height_cm: 175.0, sex: :male) }
    before do
      user_profile
      create(:weight, user: user, weight_kg: 70.0)
    end
    let(:profile) { create(:nutrition_profile, user: user, activity_level: :moderate) }

    it 'calculates TDEE by multiplying BMR with activity level' do
      tdee = profile.calculate_tdee
      bmr = profile.calculate_bmr # 1649
      # TDEE = BMR * 1.55 (moderate) = 1649 * 1.55 = 2555.95
      expect(tdee).to eq(2556)
    end
  end

  describe 'target calorie calculations' do
    let(:user) { create(:user) }
    let(:user_profile) { create(:user_profile, user: user, birth_date: 30.years.ago, height_cm: 175.0, sex: :male) }

    before do
      user_profile
      create(:weight, user: user, weight_kg: 70.0)
    end

    context 'for maintenance goal' do
      let(:profile) { create(:nutrition_profile, user: user, activity_level: :moderate, goal: :maintain) }

      it 'returns TDEE as target calories' do
        target = profile.calculate_target_calories
        tdee = profile.calculate_tdee
        expect(target).to eq(tdee)
      end
    end

    context 'for weight loss goal' do
      let(:profile) { create(:nutrition_profile, user: user, activity_level: :moderate, goal: :lose_weight, rate: 0.5) }

      it 'calculates deficit based on goal rate' do
        target = profile.calculate_target_calories
        tdee = profile.calculate_tdee
        # 0.5 kg/week * 7700 cal/kg / 7 days = 550 cal deficit per day
        expected_target = tdee - 550
        expect(target).to eq(expected_target)
      end

      it 'enforces minimum calorie intake of 1200' do
        # Create profile that would result in very low calories
        light_user = create(:user)
        create(:user_profile, user: light_user, birth_date: 30.years.ago, height_cm: 150.0, sex: :female)
        create(:weight, user: light_user, weight_kg: 50.0)
        profile = create(:nutrition_profile, user: light_user, activity_level: :sedentary, goal: :lose_weight, rate: 1.0)
        target = profile.calculate_target_calories
        expect(target).to be >= 1200
      end
    end

    context 'for muscle gain goal' do
      let(:profile) { create(:nutrition_profile, user: user, activity_level: :moderate, goal: :gain_muscle, rate: 0.25) }

      it 'calculates surplus based on goal rate' do
        target = profile.calculate_target_calories
        tdee = profile.calculate_tdee
        # 0.25 kg/week * 7700 cal/kg / 7 days = 275 cal surplus per day
        # Actual calculation: (0.25 * 7700) / 7 = 275, but rounding may affect final result
        expect(target).to be > tdee
        surplus = target - tdee
        expect(surplus).to be > 250 # Reasonable surplus for muscle gain
        expect(surplus).to be < 350 # Not too excessive
      end
    end
  end

  describe 'macro target calculations' do
    let(:user) { create(:user) }
    let(:user_profile) { create(:user_profile, user: user, birth_date: 30.years.ago, height_cm: 175.0, sex: :male) }

    before do
      user_profile
      create(:weight, user: user, weight_kg: 70.0)
    end

    context 'for balanced diet' do
      let(:profile) { create(:nutrition_profile, user: user, activity_level: :moderate, goal: :maintain, diet_type: :balanced) }

      it 'calculates balanced macro distribution' do
        macros = profile.calculate_macro_targets
        expect(macros[:protein_g]).to be > 0
        expect(macros[:carbs_g]).to be > 0
        expect(macros[:fat_g]).to be > 0
      end
    end

    context 'for low carb diet' do
      let(:profile) { create(:nutrition_profile, user: user, activity_level: :moderate, goal: :maintain, diet_type: :low_carb) }

      it 'calculates low carb macro distribution' do
        macros = profile.calculate_macro_targets
        expect(macros[:protein_g]).to be > 0
        expect(macros[:carbs_g]).to be > 0
        expect(macros[:fat_g]).to be > 0
        # Low carb should have less carbs relative to other macros
        expect(macros[:carbs_g]).to be < macros[:protein_g]
      end
    end

    context 'for custom diet' do
      let(:profile) { create(:nutrition_profile, :custom_macros, user: user) }

      it 'returns the custom macro targets' do
        macros = profile.calculate_macro_targets
        expect(macros[:protein_g]).to eq(profile.target_protein_g)
        expect(macros[:carbs_g]).to eq(profile.target_carbs_g)
        expect(macros[:fat_g]).to eq(profile.target_fat_g)
      end
    end
  end

  describe '#recalculate_all!' do
    let(:user) { create(:user) }
    let(:user_profile) { create(:user_profile, user: user, birth_date: 30.years.ago, height_cm: 175.0, sex: :male) }
    before do
      user_profile
      create(:weight, user: user, weight_kg: 70.0)
    end
    let(:profile) { create(:nutrition_profile, user: user, activity_level: :moderate, goal: :maintain, diet_type: :balanced) }

    it 'updates all calculated values and saves the record' do
      expect { profile.recalculate_all! }.to change { profile.calculated_at }
      expect(profile.bmr).to be > 0
      expect(profile.tdee).to be > 0
      expect(profile.target_calories).to be > 0
      expect(profile.target_protein_g).to be > 0
      expect(profile.target_carbs_g).to be > 0
      expect(profile.target_fat_g).to be > 0
    end
  end

  describe '#needs_recalculation?' do
    let(:user) { create(:user) }
    before { create(:weight, user: user, weight_kg: 70.0) }
    let(:profile) { create(:nutrition_profile, user: user) }

    it 'returns true when never calculated' do
      profile.calculated_at = nil
      expect(profile.needs_recalculation?).to be true
    end

    it 'returns true when calculated more than a day ago' do
      profile.calculated_at = 2.days.ago
      expect(profile.needs_recalculation?).to be true
    end

    it 'returns false when recently calculated' do
      profile.update!(calculated_at: 1.hour.ago, bmr: 1500, tdee: 2000, target_calories: 2000)
      expect(profile.needs_recalculation?).to be false
    end
  end
end 