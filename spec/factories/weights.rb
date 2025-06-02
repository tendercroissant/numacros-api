FactoryBot.define do
  factory :weight do
    association :user
    weight_kg { 70.0 }
    recorded_at { Time.current }

    trait :light do
      weight_kg { 60.0 }
    end

    trait :heavy do
      weight_kg { 90.0 }
    end

    trait :yesterday do
      recorded_at { 1.day.ago }
    end

    trait :week_ago do
      recorded_at { 1.week.ago }
    end

    trait :male_average do
      weight_kg { 80.0 }
    end

    trait :female_average do
      weight_kg { 65.0 }
    end
  end
end 