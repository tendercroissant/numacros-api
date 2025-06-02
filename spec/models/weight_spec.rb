require 'rails_helper'

RSpec.describe Weight, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:weight_kg) }
    it { should validate_presence_of(:recorded_at) }
    it { should validate_presence_of(:user_id) }
    it { should validate_numericality_of(:weight_kg).is_greater_than(30).is_less_than(500) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:weight1) { create(:weight, user: user, recorded_at: 3.days.ago) }
    let!(:weight2) { create(:weight, user: user, recorded_at: 1.day.ago) }
    let!(:weight3) { create(:weight, user: user, recorded_at: 2.days.ago) }

    describe '.ordered' do
      it 'returns weights in descending order by recorded_at' do
        expect(user.weights.ordered).to eq([weight2, weight3, weight1])
      end
    end

    describe '.recent' do
      it 'returns the 10 most recent weights' do
        expect(user.weights.recent.count).to eq(3)
        expect(user.weights.recent.first).to eq(weight2)
      end
    end
  end

  describe 'class methods' do
    let(:user) { create(:user) }
    let!(:weight1) { create(:weight, user: user, weight_kg: 70.0, recorded_at: 3.days.ago) }
    let!(:weight2) { create(:weight, user: user, weight_kg: 72.0, recorded_at: 1.day.ago) }

    describe '.current_for_user' do
      it 'returns the most recent weight for a user' do
        expect(Weight.current_for_user(user)).to eq(weight2)
      end
    end

    describe '.history_for_user' do
      it 'returns weight history for a user' do
        history = Weight.history_for_user(user, limit: 5)
        expect(history).to eq([weight2, weight1])
      end
    end
  end

  describe 'instance methods' do
    let(:weight) { create(:weight, weight_kg: 70.0) }

    describe '#weight_lbs' do
      it 'converts kg to pounds correctly' do
        expect(weight.weight_lbs).to eq(154.3)
      end
    end
  end

  describe 'unit conversion class methods' do
    describe '.pounds_to_kg' do
      it 'converts pounds to kilograms correctly' do
        expect(Weight.pounds_to_kg(154.3)).to be_within(0.1).of(70.0)
      end
    end

    describe '.kg_to_pounds' do
      it 'converts kilograms to pounds correctly' do
        expect(Weight.kg_to_pounds(70.0)).to be_within(0.1).of(154.3)
      end
    end
  end
end 