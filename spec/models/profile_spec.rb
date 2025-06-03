require 'rails_helper'

RSpec.describe Profile, type: :model do
  describe 'factories' do
    it 'creates a valid profile' do
      profile = create(:profile)
      expect(profile).to be_valid
    end

    it 'creates a user with profile trait' do
      user = create(:user, :with_profile)
      expect(user.profile).to be_present
      expect(user.profile.name).to eq('John Doe')
    end

    it 'creates male profile' do
      profile = create(:profile, :male)
      expect(profile.gender).to eq('male')
      expect(profile.name).to eq('John Doe')
    end

    it 'creates female profile' do
      profile = create(:profile, :female)
      expect(profile.gender).to eq('female')
      expect(profile.name).to eq('Jane Doe')
    end

    it 'creates keto profile' do
      profile = create(:profile, :keto)
      expect(profile.diet_type).to eq('keto')
    end

    it 'creates profile with default diet_type' do
      profile = create(:profile)
      expect(profile.diet_type).to eq('balanced')
    end

    it 'assigns diet_type correctly' do
      profile = create(:profile)
      profile.diet_type = :balanced
      expect(profile.diet_type).to eq('balanced')
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'enums' do
    it { should define_enum_for(:gender).with_values(male: 0, female: 1) }
  end

  describe 'validations' do
    # Use a created profile for shoulda-matchers since they need persisted data
    subject { create(:profile) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(50) }
    it { should validate_presence_of(:birth_date) }
    it { should validate_presence_of(:gender) }
    it { should validate_presence_of(:height_cm) }
    it { should validate_numericality_of(:height_cm).is_greater_than(100) }

    describe 'name format validation' do
      let(:user) { 
        u = create(:user)
        create(:weight, user: u, weight_kg: 65.0)
        u
      }

      it 'accepts valid names' do
        valid_names = ['John Doe', 'Mary-Jane Smith', "O'Connor", 'Jean-Paul', 'José María', 'Anne-Marie O\'Reilly']
        valid_names.each do |name|
          profile = build(:profile, user: user, name: name)
          expect(profile).to be_valid, "Expected '#{name}' to be valid"
        end
      end

      it 'rejects names with invalid characters' do
        invalid_names = ['John123', 'Mary@Smith', 'John#Doe', 'Jane$Doe', 'Test!User']
        invalid_names.each do |name|
          profile = build(:profile, user: user, name: name)
          expect(profile).not_to be_valid, "Expected '#{name}' to be invalid"
          expect(profile.errors[:name]).to include('can only contain letters, spaces, hyphens, apostrophes, and periods')
        end
      end

      it 'rejects names that are too short' do
        profile = build(:profile, user: user, name: 'J')
        expect(profile).not_to be_valid
        expect(profile.errors[:name]).to include('is too short (minimum is 2 characters)')
      end

      it 'rejects names that are too long' do
        long_name = 'A' * 51
        profile = build(:profile, user: user, name: long_name)
        expect(profile).not_to be_valid
        expect(profile.errors[:name]).to include('is too long (maximum is 50 characters)')
      end
    end

    describe 'weight validation' do
      let(:user) { create(:user) }
      
      it 'requires user to have a current weight after profile is saved' do
        profile = create(:profile, user: user)
        # Clear all weights to test the validation
        user.weights.destroy_all
        profile.reload
        
        expect(profile).not_to be_valid
        expect(profile.errors[:base]).to include('User must have a current weight recorded')
      end
      
      it 'is valid when user has a current weight' do
        profile = create(:profile, user: user)
        expect(profile).to be_valid
        expect(profile.weight_kg).to be_present
      end
    end

    describe 'minimum age requirement' do
      it 'is valid when user is 18 or older' do
        user = create(:user)
        create(:weight, user: user, weight_kg: 65.0)
        profile = build(:profile, user: user, birth_date: 20.years.ago.to_date)
        expect(profile).to be_valid
      end

      it 'is invalid when user is under 18' do
        user = create(:user)
        create(:weight, user: user, weight_kg: 65.0)
        profile = build(:profile, user: user, birth_date: 16.years.ago.to_date)
        expect(profile).not_to be_valid
        expect(profile.errors[:birth_date]).to include('must indicate user is at least 18 years old')
      end
    end
  end

  describe 'delegation to setting' do
    let(:user) { create(:user) }
    let(:profile) { create(:profile, user: user) }
    let(:setting) { user.setting }

    it 'delegates setting fields to setting' do
      expect(profile.unit_system).to eq(setting.unit_system)
      expect(profile.activity_level).to eq(setting.activity_level)
      expect(profile.weight_goal_type).to eq(setting.weight_goal_type)
      expect(profile.weight_goal_rate).to eq(setting.weight_goal_rate)
      expect(profile.diet_type).to eq(setting.diet_type)
    end

    it 'allows setting fields through delegation' do
      profile.unit_system = 'imperial'
      profile.activity_level = 'very_active'
      profile.setting.save!
      
      setting.reload
      expect(setting.unit_system).to eq('imperial')
      expect(setting.activity_level).to eq('very_active')
    end

    it 'delegates macronutrient calculations to setting' do
      expect(profile.bmr).to eq(setting.bmr)
      expect(profile.tdee).to eq(setting.tdee)
      expect(profile.calorie_goal).to eq(setting.calorie_goal)
      expect(profile.macronutrients).to eq(setting.macronutrients)
    end

    it 'calculates age from birth_date' do
      expect(profile.age).to eq(Date.current.year - profile.birth_date.year)
    end
  end

  describe 'macronutrient calculations' do
    let(:profile) { create(:profile, :male, :with_weight, weight_kg: 80, birth_date: '1990-05-15', height_cm: 180) }

    before do
      profile.user.setting.update!(
        activity_level: :moderately_active,
        weight_goal_type: :maintain_weight, 
        weight_goal_rate: 0.0,
        diet_type: :balanced
      )
    end

    describe '#macro_percentages' do
      it 'delegates to setting' do
        expect(profile.macro_percentages).to eq({ carbs: 40, protein: 30, fat: 30 })
      end
    end

    describe 'calorie calculations' do
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
      before do
        profile.user.setting.update!(diet_type: :high_protein) # 30/40/30
      end

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
        profile = create(:profile)
        # Remove the weight to simulate missing data
        profile.user.weights.destroy_all
        expect(profile.macronutrients).to be_nil
      end
    end
  end

  describe 'unit conversion helpers' do
    describe '.pounds_to_kg' do
      it 'converts pounds to kilograms correctly' do
        expect(Profile.pounds_to_kg(160)).to be_within(0.01).of(72.57)
      end
    end

    describe '.kg_to_pounds' do
      it 'converts kilograms to pounds correctly' do
        expect(Profile.kg_to_pounds(80)).to be_within(0.01).of(176.37)
      end
    end

    describe '.feet_inches_to_cm' do
      it 'converts feet and inches to centimeters correctly' do
        expect(Profile.feet_inches_to_cm(5, 10)).to be_within(0.01).of(177.8)
      end
    end

    describe '.cm_to_feet_inches' do
      it 'converts centimeters to feet and inches correctly' do
        feet, inches = Profile.cm_to_feet_inches(180)
        expect(feet).to eq(5)
        expect(inches).to eq(11)
      end
    end
  end
end
