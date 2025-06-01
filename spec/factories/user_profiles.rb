FactoryBot.define do
  factory :user_profile do
    association :user
    name { "Jane Doe" }
    birth_date { 25.years.ago.to_date }
  end
end
