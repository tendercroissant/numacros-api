FactoryBot.define do
  factory :user_profile do
    association :user
    name { "Jane Doe" }
    birth_date { 25.years.ago.to_date }
    gender { :female }
    weight_kg { 65.0 }
    height_cm { 165 }
    unit_system { :metric }
    activity_level { :moderately_active }
    weight_goal_type { :maintain_weight }
    weight_goal_rate { 0.0 }
    dietary_type { :balanced }

    trait :male do
      name { "John Doe" }
      gender { :male }
      weight_kg { 80.0 }
      height_cm { 180 }
    end

    trait :female do
      name { "Jane Doe" }
      gender { :female }
      weight_kg { 65.0 }
      height_cm { 165 }
    end

    trait :imperial_user do
      unit_system { :imperial }
    end

    trait :lose_weight do
      weight_goal_type { :lose_weight }
      weight_goal_rate { 1.0 }
    end

    trait :build_muscle do
      weight_goal_type { :build_muscle }
      weight_goal_rate { 0.5 }
    end

    trait :very_active do
      activity_level { :very_active }
    end

    trait :keto do
      dietary_type { :keto }
    end

    trait :high_protein do
      dietary_type { :high_protein }
    end

    trait :custom_macros do
      dietary_type { :custom }
      custom_carbs_percent { 45.0 }
      custom_protein_percent { 35.0 }
      custom_fat_percent { 20.0 }
    end
  end
end
