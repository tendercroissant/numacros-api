FactoryBot.define do
  factory :user_profile do
    association :user
    name { "John Doe" }
    birth_date { rand(18..65).years.ago.to_date }
    sex { [:male, :female].sample }
    height_cm { rand(150.0..200.0).round(1) }

    trait :male do
      sex { :male }
      height_cm { rand(165.0..195.0).round(1) }
    end

    trait :female do
      sex { :female }
      height_cm { rand(150.0..180.0).round(1) }
    end

    trait :young_adult do
      birth_date { rand(18..25).years.ago.to_date }
    end

    trait :middle_aged do
      birth_date { rand(35..50).years.ago.to_date }
    end

    trait :tall do
      height_cm { rand(180.0..200.0).round(1) }
    end

    trait :short do
      height_cm { rand(150.0..165.0).round(1) }
    end
  end
end