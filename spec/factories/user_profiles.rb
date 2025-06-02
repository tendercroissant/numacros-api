FactoryBot.define do
  factory :user_profile do
    association :user
    name { "Jane Doe" }
    birth_date { 25.years.ago.to_date }
    gender { :female }
    height_cm { 165 }
    unit_system { :metric }
    activity_level { :moderately_active }
    weight_goal_type { :maintain_weight }
    weight_goal_rate { 0.0 }
    diet_type { :balanced }

    trait :male do
      name { "John Doe" }
      gender { :male }
      height_cm { 180 }
    end

    trait :female do
      name { "Jane Doe" }
      gender { :female }
      height_cm { 165 }
    end

    trait :lose_weight do
      weight_goal_type { :lose_weight }
      weight_goal_rate { 1.0 }
    end

    trait :gain_weight do
      weight_goal_type { :build_muscle }
      weight_goal_rate { 0.5 }
    end

    trait :very_active do
      activity_level { :very_active }
    end

    trait :keto do
      diet_type { :keto }
    end

    trait :high_protein do
      diet_type { :high_protein }
    end

    # Create a default weight entry before creating the profile
    before(:create) do |profile|
      create(:weight, user: profile.user, weight_kg: 65.0)
    end

    trait :imperial_user do
      unit_system { :imperial }
    end

    # Helper trait to create a profile with specific weight
    trait :with_weight do
      transient do
        weight_kg { 70.0 }
      end

      after(:create) do |profile, evaluator|
        create(:weight, user: profile.user, weight_kg: evaluator.weight_kg)
      end
    end
  end
end
