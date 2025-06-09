FactoryBot.define do
  factory :nutrition_profile do
    association :user
    activity_level { [:sedentary, :light, :moderate, :active, :very_active].sample }
    goal { [:maintain, :lose_weight, :gain_muscle].sample }
    rate { rand(0.0..1.0).round(2) }
    diet_type { [:balanced, :high_protein, :low_carb, :keto, :low_fat, :mediterranean, :vegetarian, :vegan, :paleo].sample }

    trait :weight_loss do
      goal { :lose_weight }
      rate { rand(0.25..0.75).round(2) }
    end

    trait :weight_gain do
      goal { :gain_muscle }
      rate { rand(0.25..0.5).round(2) }
    end

    trait :muscle_gain do
      goal { :gain_muscle }
      rate { rand(0.1..0.3).round(2) }
      diet_type { :high_protein }
    end

    trait :maintenance do
      goal { :maintain }
      rate { 0.0 }
    end

    trait :sedentary do
      activity_level { :sedentary }
    end

    trait :active do
      activity_level { :active }
    end

    trait :custom_macros do
      diet_type { :custom }
      target_protein_g { rand(100..200) }
      target_carbs_g { rand(200..350) }
      target_fat_g { rand(60..120) }
    end

    trait :balanced do
      diet_type { :balanced }
    end

    trait :high_protein do
      diet_type { :high_protein }
    end

    trait :low_carb do
      diet_type { :low_carb }
    end

    trait :keto do
      diet_type { :keto }
    end

    trait :low_fat do
      diet_type { :low_fat }
    end

    trait :mediterranean do
      diet_type { :mediterranean }
    end

    trait :vegetarian do
      diet_type { :vegetarian }
    end

    trait :vegan do
      diet_type { :vegan }
    end

    trait :paleo do
      diet_type { :paleo }
    end
  end
end 