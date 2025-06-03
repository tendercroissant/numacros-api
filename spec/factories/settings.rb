FactoryBot.define do
  factory :setting do
    user
    unit_system { :metric }
    activity_level { :moderately_active }
    weight_goal_type { :lose_weight }
    weight_goal_rate { 0.5 }
    diet_type { :balanced }
    
    trait :imperial do
      unit_system { :imperial }
    end
    
    trait :very_active do
      activity_level { :very_active }
    end
    
    trait :maintain_weight do
      weight_goal_type { :maintain_weight }
      weight_goal_rate { 0.0 }
    end
    
    trait :build_muscle do
      weight_goal_type { :build_muscle }
      weight_goal_rate { 0.5 }
    end
    
    trait :keto do
      diet_type { :keto }
    end
    
    trait :high_protein do
      diet_type { :high_protein }
    end
  end
end 