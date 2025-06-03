FactoryBot.define do
  factory :profile do
    user
    name { 'John Doe' }
    birth_date { 25.years.ago.to_date }
    gender { :male }
    height_cm { 175 }

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

    # Create a default weight entry and setting before creating the profile
    before(:create) do |profile|
      create(:weight, user: profile.user, weight_kg: 65.0)
      # Ensure user has a valid setting - use default factory which has all required fields
      unless profile.user.setting
        create(:setting, user: profile.user)
        profile.user.reload # Ensure the association is loaded
      end
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

    # Settings-related traits that delegate to setting
    trait :lose_weight do
      after(:create) do |profile|
        profile.user.setting.update!(weight_goal_type: :lose_weight, weight_goal_rate: 1.0)
      end
    end

    trait :gain_weight do
      after(:create) do |profile|
        profile.user.setting.update!(weight_goal_type: :build_muscle, weight_goal_rate: 0.5)
      end
    end

    trait :very_active do
      after(:create) do |profile|
        profile.user.setting.update!(activity_level: :very_active)
      end
    end

    trait :keto do
      after(:create) do |profile|
        profile.user.setting.update!(diet_type: :keto)
      end
    end

    trait :high_protein do
      after(:create) do |profile|
        profile.user.setting.update!(diet_type: :high_protein)
      end
    end

    trait :imperial_user do
      after(:create) do |profile|
        profile.user.setting.update!(unit_system: :imperial)
      end
    end
  end
end
