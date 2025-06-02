require 'rails_helper'

RSpec.describe UserProfile, type: :model do
  describe 'factories' do
    it 'creates a valid user_profile' do
      profile = build(:user_profile)
      expect(profile).to be_valid
    end

    it 'creates a user with profile trait' do
      user = create(:user, :with_profile)
      expect(user.user_profile).to be_present
      expect(user.user_profile.name).to eq('Jane Doe')
    end

    it 'creates male profile' do
      profile = create(:user_profile, :male)
      expect(profile.gender).to eq('male')
      expect(profile.name).to eq('John Doe')
    end

    it 'creates female profile' do
      profile = create(:user_profile, :female)
      expect(profile.gender).to eq('female')
      expect(profile.name).to eq('Jane Doe')
    end

    it 'creates keto profile' do
      profile = create(:user_profile, :keto)
      expect(profile.dietary_type).to eq('keto')
    end

    it 'creates custom macros profile' do
      profile = create(:user_profile, :custom_macros)
      expect(profile.dietary_type).to eq('custom')
      expect(profile.custom_carbs_percent).to eq(45.0)
      expect(profile.custom_protein_percent).to eq(35.0)
      expect(profile.custom_fat_percent).to eq(20.0)
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_one(:macronutrient_target).dependent(:destroy) }
  end

  describe 'enums' do
    it { should define_enum_for(:gender).with_values(male: 0, female: 1) }
    it { should define_enum_for(:unit_system).with_values(metric: 0, imperial: 1) }
    it { should define_enum_for(:activity_level).with_values(
      sedentary: 0, lightly_active: 1, moderately_active: 2, very_active: 3, extra_active: 4
    ) }
    it { should define_enum_for(:weight_goal_type).with_values(
      lose_weight: 0, maintain_weight: 1, build_muscle: 2
    ) }
    it { should define_enum_for(:dietary_type).with_values(
      balanced: 0, low_carb: 1, keto: 2, high_protein: 3, paleo: 4, vegetarian: 5, vegan: 6, mediterranean: 7, custom: 8
    ) }
  end

  describe 'validations' do
    subject { build(:user_profile) }

    it { should validate_presence_of(:birth_date) }
    it { should validate_presence_of(:gender) }
    it { should validate_presence_of(:weight_kg) }
    it { should validate_presence_of(:height_cm) }
    it { should validate_presence_of(:unit_system) }
    it { should validate_presence_of(:activity_level) }
    it { should validate_presence_of(:weight_goal_type) }
    it { should validate_presence_of(:weight_goal_rate) }
    it { should validate_presence_of(:dietary_type) }

    it { should validate_numericality_of(:weight_kg).is_greater_than(30) }
    it { should validate_numericality_of(:height_cm).is_greater_than(100) }
    it { should validate_inclusion_of(:weight_goal_rate).in_array([0.0, 0.5, 1.0, 2.0]) }

    describe 'minimum age requirement' do
      let(:user) { create(:user) }
      
      context 'when user is 13 or older' do
        it 'is valid' do
          profile = build(:user_profile, user: user, birth_date: 15.years.ago.to_date)
          expect(profile).to be_valid
        end
      end

      context 'when user is under 13' do
        it 'is invalid' do
          profile = build(:user_profile, user: user, birth_date: 10.years.ago.to_date)
          expect(profile).not_to be_valid
          expect(profile.errors[:birth_date]).to include('must indicate user is at least 13 years old')
        end
      end
    end

    describe 'weight goal rate compatibility' do
      let(:user) { create(:user) }

      context 'when maintaining weight' do
        it 'requires rate to be 0.0' do
          profile = build(:user_profile, user: user, weight_goal_type: :maintain_weight, weight_goal_rate: 1.0)
          expect(profile).not_to be_valid
          expect(profile.errors[:weight_goal_rate]).to include('must be 0.0 when maintaining weight')
        end

        it 'is valid with rate 0.0' do
          profile = build(:user_profile, user: user, weight_goal_type: :maintain_weight, weight_goal_rate: 0.0)
          expect(profile).to be_valid
        end
      end

      context 'when losing weight' do
        it 'requires rate to be 0.5, 1.0, or 2.0' do
          profile = build(:user_profile, user: user, weight_goal_type: :lose_weight, weight_goal_rate: 0.25)
          expect(profile).not_to be_valid
          expect(profile.errors[:weight_goal_rate]).to include('must be 0.5, 1.0, or 2.0 when losing weight')
        end

        it 'is valid with rate 1.0' do
          profile = build(:user_profile, user: user, weight_goal_type: :lose_weight, weight_goal_rate: 1.0)
          expect(profile).to be_valid
        end
      end

      context 'when building muscle' do
        it 'requires rate to be 0.5 or 1.0' do
          profile = build(:user_profile, user: user, weight_goal_type: :build_muscle, weight_goal_rate: 2.0)
          expect(profile).not_to be_valid
          expect(profile.errors[:weight_goal_rate]).to include('must be 0.5 or 1.0 when building muscle')
        end

        it 'is valid with rate 0.5' do
          profile = build(:user_profile, user: user, weight_goal_type: :build_muscle, weight_goal_rate: 0.5)
          expect(profile).to be_valid
        end
      end
    end

    describe 'custom macro validation' do
      let(:user) { create(:user) }

      context 'when dietary type is custom' do
        it 'requires all custom macro percentages' do
          profile = build(:user_profile, user: user, dietary_type: :custom)
          expect(profile).not_to be_valid
          expect(profile.errors[:base]).to include('Custom macro percentages are required when dietary type is custom')
        end

        it 'requires macro percentages to add up to 100%' do
          profile = build(:user_profile, user: user, dietary_type: :custom, 
                         custom_carbs_percent: 40, custom_protein_percent: 30, custom_fat_percent: 20)
          expect(profile).not_to be_valid
          expect(profile.errors[:base]).to include('Custom macro percentages must add up to 100%')
        end

        it 'requires macro percentages to be positive' do
          profile = build(:user_profile, user: user, dietary_type: :custom, 
                         custom_carbs_percent: -10, custom_protein_percent: 60, custom_fat_percent: 50)
          expect(profile).not_to be_valid
          expect(profile.errors[:base]).to include('Custom macro percentages must be positive')
        end

        it 'is valid with correct custom macro percentages' do
          profile = build(:user_profile, user: user, dietary_type: :custom, 
                         custom_carbs_percent: 40, custom_protein_percent: 30, custom_fat_percent: 30)
          expect(profile).to be_valid
        end
      end

      context 'when dietary type is not custom' do
        it 'is valid without custom macro percentages' do
          profile = build(:user_profile, user: user, dietary_type: :balanced)
          expect(profile).to be_valid
        end
      end
    end
  end

  describe 'macronutrient target lifecycle' do
    describe 'automatic creation' do
      it 'creates macronutrient target when profile is created with complete data' do
        profile = create(:user_profile)
        expect(profile.macronutrient_target).to be_present
        expect(profile.macronutrient_target.calories).to be > 0
      end

      it 'does not create target for incomplete profile' do
        profile = build(:user_profile, weight_kg: nil)
        expect(profile.valid?).to be false
        # Test that a profile without required nutrition fields won't have targets calculated
        expect(profile.calorie_goal).to be_nil
      end
    end

    describe 'automatic updates' do
      let!(:profile) { create(:user_profile, weight_goal_type: :maintain_weight, weight_goal_rate: 0.0) }
      
      before do
        # Ensure initial target exists
        expect(profile.macronutrient_target).to be_present
      end

      it 'updates target when weight changes' do
        initial_calories = profile.macronutrient_target.calories
        profile.update!(weight_kg: profile.weight_kg + 10)
        
        profile.reload
        expect(profile.macronutrient_target.calories).not_to eq(initial_calories)
      end

      it 'updates target when activity level changes' do
        initial_calories = profile.macronutrient_target.calories
        profile.update!(activity_level: :very_active)
        
        profile.reload
        expect(profile.macronutrient_target.calories).not_to eq(initial_calories)
      end

      it 'updates target when dietary type changes' do
        initial_carbs = profile.macronutrient_target.carbs_grams
        profile.update!(dietary_type: :keto)
        
        profile.reload
        expect(profile.macronutrient_target.carbs_grams).not_to eq(initial_carbs)
      end

      it 'does not update target when non-nutrition fields change' do
        initial_updated_at = profile.macronutrient_target.updated_at
        sleep(0.01) # Ensure time difference
        profile.update!(name: "New Name")
        
        profile.reload
        expect(profile.macronutrient_target.updated_at).to eq(initial_updated_at)
      end
    end

    describe 'custom dietary type updates' do
      let!(:profile) { create(:user_profile, :custom_macros) }

      it 'updates target when custom percentages change' do
        initial_protein = profile.macronutrient_target.protein_grams
        profile.update!(custom_protein_percent: 50.0, custom_carbs_percent: 30.0, custom_fat_percent: 20.0)
        
        profile.reload
        expect(profile.macronutrient_target.protein_grams).not_to eq(initial_protein)
      end
    end
  end

  describe 'calculation methods' do
    let(:profile) { create(:user_profile, :male, birth_date: '1990-05-15', weight_kg: 80, height_cm: 180, activity_level: :moderately_active) }

    describe '#age' do
      it 'calculates age correctly' do
        expect(profile.age).to eq(Date.current.year - 1990)
      end
    end

    describe '#bmr' do
      it 'calculates BMR for male correctly' do
        expected_bmr = 10 * 80 + 6.25 * 180 - 5 * profile.age + 5
        expect(profile.bmr).to eq(expected_bmr)
      end

      it 'calculates BMR for female correctly' do
        female_profile = create(:user_profile, :female, birth_date: '1990-05-15', weight_kg: 65, height_cm: 165)
        expected_bmr = 10 * 65 + 6.25 * 165 - 5 * female_profile.age - 161
        expect(female_profile.bmr).to eq(expected_bmr)
      end
    end

    describe '#tdee' do
      it 'calculates TDEE correctly' do
        expected_tdee = profile.bmr * 1.55  # moderately_active multiplier
        expect(profile.tdee).to eq(expected_tdee)
      end
    end

    describe '#calorie_adjustment' do
      it 'returns negative adjustment for weight loss' do
        profile.update!(weight_goal_type: :lose_weight, weight_goal_rate: 1.0)
        expect(profile.calorie_adjustment).to eq(-500)
      end

      it 'returns positive adjustment for muscle building' do
        profile.update!(weight_goal_type: :build_muscle, weight_goal_rate: 0.5)
        expect(profile.calorie_adjustment).to eq(250)
      end

      it 'returns zero adjustment for maintaining weight' do
        profile.update!(weight_goal_type: :maintain_weight, weight_goal_rate: 0.0)
        expect(profile.calorie_adjustment).to eq(0)
      end
    end

    describe '#calorie_goal' do
      it 'calculates calorie goal correctly' do
        profile.update!(weight_goal_type: :lose_weight, weight_goal_rate: 1.0)
        expected_goal = (profile.tdee - 500).round
        expect(profile.calorie_goal).to eq(expected_goal)
      end
    end
  end

  describe 'macronutrient calculations' do
    let(:profile) { create(:user_profile, :male, birth_date: '1990-05-15', weight_kg: 80, height_cm: 180, activity_level: :moderately_active, weight_goal_type: :maintain_weight, weight_goal_rate: 0.0) }

    describe '#macro_percentages' do
      context 'with balanced diet' do
        it 'returns correct percentages' do
          profile.update!(dietary_type: :balanced)
          expect(profile.macro_percentages).to eq({ carbs: 40, protein: 30, fat: 30 })
        end
      end

      context 'with keto diet' do
        it 'returns correct percentages' do
          profile.update!(dietary_type: :keto)
          expect(profile.macro_percentages).to eq({ carbs: 5, protein: 20, fat: 75 })
        end
      end

      context 'with custom diet' do
        it 'returns custom percentages' do
          profile.update!(dietary_type: :custom, custom_carbs_percent: 45, custom_protein_percent: 25, custom_fat_percent: 30)
          expect(profile.macro_percentages).to eq({ carbs: 45.0, protein: 25.0, fat: 30.0 })
        end

        it 'returns nil without custom percentages' do
          # Create a profile with custom type but missing percentages using build (not update!)
          custom_profile = build(:user_profile, dietary_type: :custom, custom_carbs_percent: nil, custom_protein_percent: nil, custom_fat_percent: nil)
          expect(custom_profile.macro_percentages).to be_nil
        end
      end
    end

    describe 'calorie calculations' do
      before { profile.update!(dietary_type: :balanced) } # 40/30/30

      it 'calculates carbs calories correctly' do
        expected_carbs_calories = (profile.calorie_goal * 0.4).round
        expect(profile.carbs_calories).to eq(expected_carbs_calories)
      end

      it 'calculates protein calories correctly' do
        expected_protein_calories = (profile.calorie_goal * 0.3).round
        expect(profile.protein_calories).to eq(expected_protein_calories)
      end

      it 'calculates fat calories correctly' do
        expected_fat_calories = (profile.calorie_goal * 0.3).round
        expect(profile.fat_calories).to eq(expected_fat_calories)
      end
    end

    describe 'gram calculations' do
      before { profile.update!(dietary_type: :balanced) } # 40/30/30

      it 'calculates carbs grams correctly' do
        expected_grams = (profile.carbs_calories / 4).round
        expect(profile.carbs_grams).to eq(expected_grams)
      end

      it 'calculates protein grams correctly' do
        expected_grams = (profile.protein_calories / 4).round
        expect(profile.protein_grams).to eq(expected_grams)
      end

      it 'calculates fat grams correctly' do
        expected_grams = (profile.fat_calories / 9).round
        expect(profile.fat_grams).to eq(expected_grams)
      end
    end

    describe '#macronutrients' do
      before { profile.update!(dietary_type: :high_protein) } # 30/40/30

      it 'returns complete macronutrient breakdown' do
        macros = profile.macronutrients
        
        expect(macros[:calories]).to eq(profile.calorie_goal)
        expect(macros[:carbs][:percent]).to eq(30)
        expect(macros[:protein][:percent]).to eq(40)
        expect(macros[:fat][:percent]).to eq(30)
        
        expect(macros[:carbs][:grams]).to be_present
        expect(macros[:carbs][:calories]).to be_present
        expect(macros[:protein][:grams]).to be_present
        expect(macros[:protein][:calories]).to be_present
        expect(macros[:fat][:grams]).to be_present
        expect(macros[:fat][:calories]).to be_present
      end

      it 'returns nil without complete profile' do
        incomplete_profile = build(:user_profile, weight_kg: nil)
        expect(incomplete_profile.macronutrients).to be_nil
      end
    end
  end

  describe 'unit conversion helpers' do
    describe '.pounds_to_kg' do
      it 'converts pounds to kilograms correctly' do
        expect(UserProfile.pounds_to_kg(160)).to be_within(0.01).of(72.57)
      end
    end

    describe '.kg_to_pounds' do
      it 'converts kilograms to pounds correctly' do
        expect(UserProfile.kg_to_pounds(80)).to be_within(0.01).of(176.37)
      end
    end

    describe '.feet_inches_to_cm' do
      it 'converts feet and inches to centimeters correctly' do
        expect(UserProfile.feet_inches_to_cm(5, 10)).to be_within(0.01).of(177.8)
      end
    end

    describe '.cm_to_feet_inches' do
      it 'converts centimeters to feet and inches correctly' do
        feet, inches = UserProfile.cm_to_feet_inches(180)
        expect(feet).to eq(5)
        expect(inches).to eq(11)
      end
    end
  end
end
