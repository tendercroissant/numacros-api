FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_profile do
      after(:create) do |user|
        create(:user_profile, user: user)
      end
    end

    trait :with_profile_and_weight do
      after(:create) do |user|
        create(:user_profile, user: user)
        create(:weight, user: user, weight_kg: 70.0, recorded_at: Time.current)
      end
    end
  end
end
