FactoryBot.define do
  factory :macronutrient_target do
    association :user_profile
    calories { 2000 }
    carbs_grams { 200 }
    protein_grams { 150 }
    fat_grams { 67 }

    trait :high_calorie do
      calories { 3000 }
      carbs_grams { 300 }
      protein_grams { 225 }
      fat_grams { 100 }
    end

    trait :low_carb do
      calories { 2000 }
      carbs_grams { 50 }
      protein_grams { 200 }
      fat_grams { 133 }
    end
  end
end
