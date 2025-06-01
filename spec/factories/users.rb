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
  end
end
