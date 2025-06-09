require 'rails_helper'

RSpec.describe Weight, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:weight) }
    
    it { should validate_presence_of(:weight_kg) }
    it { should validate_presence_of(:recorded_at) }
    
    it 'validates weight_kg is positive and within reasonable range' do
      weight = build(:weight, weight_kg: -5.0)
      expect(weight).not_to be_valid
      
      weight.weight_kg = 0.0
      expect(weight).not_to be_valid
      
      weight.weight_kg = 1500.0
      expect(weight).not_to be_valid
      expect(weight.errors[:weight_kg]).to include('must be between 0.0 and 1000.0 kg')
      
      weight.weight_kg = 75.0
      expect(weight).to be_valid
    end

    it 'validates uniqueness of user_id scoped to recorded_at' do
      existing_weight = create(:weight, recorded_at: Time.current)
      duplicate_weight = build(:weight, user: existing_weight.user, recorded_at: existing_weight.recorded_at)
      
      expect(duplicate_weight).not_to be_valid
      expect(duplicate_weight.errors[:user_id]).to include('can only have one weight entry per exact time')
    end

    it 'validates recorded_at is not in the future' do
      weight = build(:weight, recorded_at: 1.day.from_now)
      expect(weight).not_to be_valid
      expect(weight.errors[:recorded_at]).to include('cannot be in the future')
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:weight1) { create(:weight, user: user, weight_kg: 80.0, recorded_at: 3.days.ago) }
    let!(:weight2) { create(:weight, user: user, weight_kg: 79.0, recorded_at: 2.days.ago) }
    let!(:weight3) { create(:weight, user: user, weight_kg: 78.0, recorded_at: 1.day.ago) }

    describe '.for_user' do
      it 'returns weights for specific user' do
        other_user = create(:user)
        create(:weight, user: other_user)
        
        weights = Weight.for_user(user)
        expect(weights.count).to eq(3)
        expect(weights.pluck(:user_id).uniq).to eq([user.id])
      end
    end

    describe '.recent_first' do
      it 'orders weights by recorded_at descending' do
        weights = Weight.for_user(user).recent_first
        expect(weights.pluck(:weight_kg)).to eq([78.0, 79.0, 80.0])
      end
    end

    describe '.oldest_first' do
      it 'orders weights by recorded_at ascending' do
        weights = Weight.for_user(user).oldest_first
        expect(weights.pluck(:weight_kg)).to eq([80.0, 79.0, 78.0])
      end
    end

    describe '.in_date_range' do
      it 'returns weights within date range' do
        weights = Weight.for_user(user).in_date_range(2.5.days.ago, 1.5.days.ago)
        expect(weights.count).to eq(1)
        expect(weights.first.weight_kg).to eq(79.0)
      end
    end

    describe '.recent' do
      it 'limits results to specified number' do
        weights = Weight.for_user(user).recent(2)
        expect(weights.count).to eq(2)
        expect(weights.pluck(:weight_kg)).to eq([78.0, 79.0])
      end
    end
  end

  describe '.latest_for_user' do
    let(:user) { create(:user) }

    it 'returns the most recent weight entry for user' do
      create(:weight, user: user, weight_kg: 80.0, recorded_at: 3.days.ago)
      latest = create(:weight, user: user, weight_kg: 78.0, recorded_at: 1.day.ago)
      
      expect(Weight.latest_for_user(user)).to eq(latest)
    end

    it 'returns nil when user has no weights' do
      expect(Weight.latest_for_user(user)).to be_nil
    end
  end

  describe '.trend_for_user' do
    let(:user) { create(:user) }

    context 'with sufficient data' do
      before do
        create(:weight, user: user, weight_kg: 80.0, recorded_at: 28.days.ago)
        create(:weight, user: user, weight_kg: 78.0, recorded_at: Time.current)
      end

      it 'calculates weight trend in kg per week' do
        trend = Weight.trend_for_user(user, days: 30)
        # 2kg loss over 28 days = 2/28 * 7 = 0.5 kg/week loss
        expect(trend).to eq(-0.5)
      end
    end

    context 'with insufficient data' do
      it 'returns nil when user has fewer than 2 entries' do
        create(:weight, user: user, weight_kg: 80.0, recorded_at: 1.day.ago)
        expect(Weight.trend_for_user(user)).to be_nil
      end

      it 'returns nil when entries are on the same date' do
        same_date = 1.day.ago
        create(:weight, user: user, weight_kg: 80.0, recorded_at: same_date)
        create(:weight, user: user, weight_kg: 79.0, recorded_at: same_date + 1.hour)
        expect(Weight.trend_for_user(user, days: 1)).to be_nil
      end
    end
  end

  describe '#weight_change_from_previous' do
    let(:user) { create(:user) }

    it 'calculates change from previous entry' do
      create(:weight, user: user, weight_kg: 80.0, recorded_at: 2.days.ago)
      current_weight = create(:weight, user: user, weight_kg: 78.5, recorded_at: 1.day.ago)
      
      expect(current_weight.weight_change_from_previous).to eq(-1.5)
    end

    it 'returns nil when no previous entry exists' do
      first_weight = create(:weight, user: user, weight_kg: 80.0)
      expect(first_weight.weight_change_from_previous).to be_nil
    end
  end

  describe '#days_since_previous' do
    let(:user) { create(:user) }

    it 'calculates days since previous entry' do
      create(:weight, user: user, weight_kg: 80.0, recorded_at: 5.days.ago)
      current_weight = create(:weight, user: user, weight_kg: 78.5, recorded_at: 1.day.ago)
      
      expect(current_weight.days_since_previous).to eq(4)
    end

    it 'returns nil when no previous entry exists' do
      first_weight = create(:weight, user: user, weight_kg: 80.0)
      expect(first_weight.days_since_previous).to be_nil
    end
  end

  describe 'nutrition profile integration' do
    let(:user) { create(:user) }
    let!(:user_profile) { create(:user_profile, user: user) }
    
    before do
      # Create initial weight so nutrition profile can be created
      create(:weight, user: user, weight_kg: 75.0, recorded_at: 3.days.ago)
    end
    
    let!(:nutrition_profile) { create(:nutrition_profile, user: user) }

    it 'triggers nutrition profile recalculation when created' do
      expect(nutrition_profile).to receive(:recalculate_all!)
      create(:weight, user: user, weight_kg: 75.0)
    end

    it 'only recalculates for the most recent weight' do
      # Create first weight
      first_weight = create(:weight, user: user, weight_kg: 80.0, recorded_at: 2.days.ago)
      
      # Create second weight (should trigger recalculation)
      expect(nutrition_profile).to receive(:recalculate_all!)
      create(:weight, user: user, weight_kg: 78.0, recorded_at: 1.day.ago)
    end

    it 'does not recalculate when nutrition profile does not exist' do
      user_without_nutrition = create(:user)
      expect { create(:weight, user: user_without_nutrition, weight_kg: 75.0) }.not_to raise_error
    end
  end
end 