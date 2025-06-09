FactoryBot.define do
  factory :weight do
    association :user
    weight_kg { rand(50.0..120.0).round(1) }
    recorded_at { Time.current }

    trait :recent do
      recorded_at { rand(1..7).days.ago }
    end

    trait :last_week do
      recorded_at { rand(7..14).days.ago }
    end

    trait :last_month do
      recorded_at { rand(20..35).days.ago }
    end

    trait :three_months_ago do
      recorded_at { rand(80..100).days.ago }
    end

    # For creating weight loss progression
    trait :weight_loss_start do
      weight_kg { 85.0 }
      recorded_at { 90.days.ago }
    end

    trait :weight_loss_mid do
      weight_kg { 82.0 }
      recorded_at { 45.days.ago }
    end

    trait :weight_loss_current do
      weight_kg { 79.5 }
      recorded_at { Time.current }
    end

    # For creating weight gain progression
    trait :weight_gain_start do
      weight_kg { 65.0 }
      recorded_at { 60.days.ago }
    end

    trait :weight_gain_current do
      weight_kg { 68.5 }
      recorded_at { Time.current }
    end

    # For creating maintenance
    trait :stable_weight do
      weight_kg { 75.0 }
    end
  end

  # Factory for creating a weight progression (multiple entries)
  factory :weight_progression, class: 'Weight' do
    transient do
      user { nil }
      start_weight { 80.0 }
      end_weight { 75.0 }
      days_span { 90 }
      entries_count { 12 }
    end

    after(:build) do |weight, evaluator|
      next unless evaluator.user

      # Create a series of weight entries
      (0...evaluator.entries_count).each do |i|
        days_ago = evaluator.days_span - (i * evaluator.days_span / evaluator.entries_count.to_f)
        progress = i / (evaluator.entries_count - 1).to_f
        current_weight = evaluator.start_weight + (evaluator.end_weight - evaluator.start_weight) * progress
        
        # Add some random variation
        current_weight += rand(-0.5..0.5)
        
        FactoryBot.create(:weight,
          user: evaluator.user,
          weight_kg: current_weight.round(1),
          recorded_at: days_ago.days.ago
        )
      end
    end
  end
end