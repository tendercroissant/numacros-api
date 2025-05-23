FactoryBot.define do
  factory :email_subscription do
    email { "test@example.com" }
    name { "Test User" }
  end
end 