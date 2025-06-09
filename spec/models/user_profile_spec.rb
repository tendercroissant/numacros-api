require 'rails_helper'

RSpec.describe UserProfile, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_one(:nutrition_profile).through(:user) }
  end

  describe 'validations' do
    subject { build(:user_profile) }
    
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(1).is_at_most(100) }
    it { should validate_presence_of(:birth_date) }
    it { should validate_presence_of(:sex) }
    it { should validate_presence_of(:height_cm) }
    
    it 'validates height_cm is within reasonable range' do
      profile = build(:user_profile, height_cm: 40.0)
      expect(profile).not_to be_valid
      expect(profile.errors[:height_cm]).to include('must be between 50.0 and 300.0 cm')
      
      profile.height_cm = 350.0
      expect(profile).not_to be_valid
      
      profile.height_cm = 175.0
      expect(profile).to be_valid
    end

    it 'validates birth_date is not in the future' do
      profile = build(:user_profile, birth_date: 1.day.from_now)
      expect(profile).not_to be_valid
      expect(profile.errors[:birth_date]).to include('cannot be in the future')
    end

    it 'validates minimum age requirement' do
      profile = build(:user_profile, birth_date: 10.years.ago)
      expect(profile).not_to be_valid
      expect(profile.errors[:birth_date]).to include('user must be at least 13 years old')
      
      profile.birth_date = 15.years.ago
      expect(profile).to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:sex).with_values(male: 0, female: 1) }
  end

  describe '#age' do
    it 'calculates age correctly' do
      profile = build(:user_profile, birth_date: 25.years.ago.to_date)
      expect(profile.age).to eq(25)
    end

    it 'handles birthday this year correctly' do
      birth_date = Date.new(Date.current.year - 30, Date.current.month + 1, Date.current.day)
      profile = build(:user_profile, birth_date: birth_date)
      expect(profile.age).to eq(29) # Haven't had birthday yet this year
    end

    it 'returns nil if birth_date is not present' do
      profile = build(:user_profile, birth_date: nil)
      expect(profile.age).to be_nil
    end
  end

  describe '#height_m' do
    it 'converts height from cm to meters' do
      profile = build(:user_profile, height_cm: 175.5)
      expect(profile.height_m).to eq(1.755)
    end
  end

  describe '#bmi' do
    let(:user) { create(:user) }
    let(:user_profile) { create(:user_profile, user: user, height_cm: 175.0) }

    context 'with weight from weights table' do
      it 'calculates BMI using latest weight entry' do
        create(:weight, user: user, weight_kg: 70.0)
        
        bmi = user_profile.bmi
        expect(bmi).to eq(22.9) # 70 / (1.75^2) = 22.857, rounded to 22.9
      end
    end

    context 'with no weight entries' do
      it 'returns nil when no weights exist' do
        expect(user_profile.bmi).to be_nil
      end
    end

    it 'returns nil when no weight is available' do
      expect(user_profile.bmi).to be_nil
    end
  end

  describe '#bmi_category' do
    let(:user) { create(:user) }
    let(:user_profile) { create(:user_profile, user: user, height_cm: 175.0) }

    it 'categorizes underweight correctly' do
      create(:weight, user: user, weight_kg: 55.0) # BMI ~18.0
      expect(user_profile.bmi_category).to eq(:underweight)
    end

    it 'categorizes normal weight correctly' do
      create(:weight, user: user, weight_kg: 70.0) # BMI ~22.9
      expect(user_profile.bmi_category).to eq(:normal)
    end

    it 'categorizes overweight correctly' do
      create(:weight, user: user, weight_kg: 85.0) # BMI ~27.8
      expect(user_profile.bmi_category).to eq(:overweight)
    end

    it 'categorizes obese correctly' do
      create(:weight, user: user, weight_kg: 95.0) # BMI ~31.0
      expect(user_profile.bmi_category).to eq(:obese)
    end

    it 'returns nil when BMI cannot be calculated' do
      expect(user_profile.bmi_category).to be_nil
    end
  end
end 