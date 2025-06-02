require 'rails_helper'

RSpec.describe UserProfile, type: :model do
  describe 'factories' do
    it 'creates a valid user_profile' do
      profile = create(:user_profile)
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
      expect(profile.diet_type).to eq('keto')
    end

    it 'creates profile with default diet_type' do
      profile = create(:user_profile)
      expect(profile.diet_type).to eq('balanced')
    end

    it 'assigns diet_type correctly' do
      profile = create(:user_profile, diet_type: :balanced)
      expect(profile.diet_type).to eq('balanced')
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
    it { should define_enum_for(:diet_type).with_values(
      balanced: 0, low_carb: 1, keto: 2, high_protein: 3, paleo: 4, vegetarian: 5, vegan: 6, mediterranean: 7
    ) }
  end

  describe 'validations' do
    # Use a created profile for shoulda-matchers since they need persisted data
    subject { create(:user_profile) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(50) }
    it { should validate_presence_of(:birth_date) }
    it { should validate_presence_of(:gender) }
    it { should validate_presence_of(:height_cm) }
    it { should validate_presence_of(:unit_system) }
    it { should validate_presence_of(:activity_level) }
    it { should validate_presence_of(:weight_goal_type) }
    it { should validate_presence_of(:weight_goal_rate) }
    it { should validate_presence_of(:diet_type) }

    it { should validate_numericality_of(:height_cm).is_greater_than(100) }
    it { should validate_inclusion_of(:weight_goal_rate).in_array([0.0, 0.5, 1.0, 2.0]) }

    describe 'name format validation' do
      let(:user) { 
        u = create(:user)
        create(:weight, user: u, weight_kg: 65.0)
        u
      }

      it 'accepts valid names' do
        valid_names = ['John Doe', 'Mary-Jane Smith', "O'Connor", 'Jean-Paul', 'José María', 'Anne-Marie O\'Reilly']
        valid_names.each do |name|
          profile = build(:user_profile, user: user, name: name)
          expect(profile).to be_valid, "Expected '#{name}' to be valid"
        end
      end

      it 'rejects names with invalid characters' do
        invalid_names = ['John123', 'Mary@Smith', 'John#Doe', 'Jane$Doe', 'Test!User']
        invalid_names.each do |name|
          profile = build(:user_profile, user: user, name: name)
          expect(profile).not_to be_valid, "Expected '#{name}' to be invalid"
          expect(profile.errors[:name]).to include('can only contain letters, spaces, hyphens, apostrophes, and periods')
        end
      end

      it 'rejects names that are too short' do
        profile = build(:user_profile, user: user, name: 'J')
        expect(profile).not_to be_valid
        expect(profile.errors[:name]).to include('is too short (minimum is 2 characters)')
      end

      it 'rejects names that are too long' do
        long_name = 'A' * 51
        profile = build(:user_profile, user: user, name: long_name)
        expect(profile).not_to be_valid
        expect(profile.errors[:name]).to include('is too long (maximum is 50 characters)')
      end
    end

    describe 'weight validation' do
      let(:user) { create(:user) }
      
      it 'requires user to have a current weight after profile is saved' do
        profile = create(:user_profile, user: user)
        # Clear all weights to test the validation
        user.weights.destroy_all
        profile.reload
        
        expect(profile).not_to be_valid
        expect(profile.errors[:base]).to include('User must have a current weight recorded')
      end
      
      it 'is valid when user has a current weight' do
        profile = create(:user_profile, user: user)
        expect(profile).to be_valid
        expect(profile.weight_kg).to be_present
      end
    end

    describe 'minimum age requirement' do
      it 'is valid when user is 18 or older' do
        user = create(:user)
        create(:weight, user: user, weight_kg: 65.0)
        profile = build(:user_profile, user: user, birth_date: 20.years.ago.to_date)
        expect(profile).to be_valid
      end

      it 'is invalid when user is under 18' do
        user = create(:user)
        create(:weight, user: user, weight_kg: 65.0)
        profile = build(:user_profile, user: user, birth_date: 16.years.ago.to_date)
        expect(profile).not_to be_valid
        expect(profile.errors[:birth_date]).to include('must indicate user is at least 18 years old')
      end
    end

    describe 'weight goal rate compatibility' do
      let(:user) { 
        u = create(:user)
        create(:weight, user: u, weight_kg: 65.0)
        u
      }

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
      let(:user) { 
        u = create(:user)
        create(:weight, user: u, weight_kg: 65.0)
        u
      }

      it 'creates macronutrient target when profile is created with complete data' do
        profile = create(:user_profile)
        expect(profile.macronutrient_target).to be_present
        expect(profile.macronutrient_target.calories).to be > 0
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
        # Create new weight entry instead of updating weight_kg directly
        create(:weight, user: profile.user, weight_kg: profile.weight_kg + 10)
        profile.calculate_and_store_macronutrients
        
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
        profile.update!(diet_type: :keto)
        
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
  end

  describe 'calculation methods' do
    let(:profile) { create(:user_profile, :male, :with_weight, weight_kg: 80, birth_date: '1990-05-15', height_cm: 180, activity_level: :moderately_active) }

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
        female_profile = create(:user_profile, :female, :with_weight, weight_kg: 65, birth_date: '1990-05-15', height_cm: 165)
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
    let(:profile) { create(:user_profile, :male, :with_weight, weight_kg: 80, birth_date: '1990-05-15', height_cm: 180, activity_level: :moderately_active, weight_goal_type: :maintain_weight, weight_goal_rate: 0.0) }

    describe '#macro_percentages' do
      context 'with balanced diet' do
        it 'returns correct percentages' do
          profile.update!(diet_type: :balanced)
          expect(profile.macro_percentages).to eq({ carbs: 40, protein: 30, fat: 30 })
        end
      end

      context 'with keto diet' do
        it 'returns correct percentages' do
          profile.update!(diet_type: :keto)
          expect(profile.macro_percentages).to eq({ carbs: 5, protein: 20, fat: 75 })
        end
      end
    end

    describe 'calorie calculations' do
      before { profile.update!(diet_type: :balanced) } # 40/30/30

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
      before { profile.update!(diet_type: :balanced) } # 40/30/30

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
      before { profile.update!(diet_type: :high_protein) } # 30/40/30

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

      it 'returns nil when profile lacks weight data' do
        profile = create(:user_profile)
        # Remove the weight to simulate missing data
        profile.user.weights.destroy_all
        expect(profile.macronutrients).to be_nil
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
