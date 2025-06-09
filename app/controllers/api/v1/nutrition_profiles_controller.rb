module Api
  module V1
    class NutritionProfilesController < ApplicationController
      before_action :set_nutrition_profile, only: [:show, :update]

      def show
        if @nutrition_profile
          render json: nutrition_profile_json(@nutrition_profile)
        else
          render json: { error: 'Nutrition profile not found' }, status: :not_found
        end
      end

      def create
        if @current_user.nutrition_profile.present?
          return render json: { error: 'Nutrition profile already exists' }, status: :unprocessable_entity
        end

        @nutrition_profile = @current_user.build_nutrition_profile(nutrition_profile_params)

        if @nutrition_profile.save
          render json: nutrition_profile_json(@nutrition_profile), status: :created
        else
          render json: { errors: @nutrition_profile.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        unless @nutrition_profile
          return render json: { error: 'Nutrition profile not found' }, status: :not_found
        end

        if @nutrition_profile.update(nutrition_profile_params)
          render json: nutrition_profile_json(@nutrition_profile)
        else
          render json: { errors: @nutrition_profile.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_nutrition_profile
        @nutrition_profile = @current_user.nutrition_profile
      end

      def nutrition_profile_params
        permitted_params = [
          :weight_kg, :activity_level, :goal, :goal_rate_kg_per_week, :diet_type
        ]
        
        # Allow custom macro targets if diet_type is custom
        if params.dig(:nutrition_profile, :diet_type) == 'custom'
          permitted_params += [:target_protein_g, :target_carbs_g, :target_fat_g]
        end
        
        params.require(:nutrition_profile).permit(permitted_params)
      end

      def nutrition_profile_json(profile)
        {
          id: profile.id,
          current_weight: profile.current_weight,
          weight_kg: profile.weight_kg,
          activity_level: profile.activity_level,
          goal: profile.goal,
          goal_rate_kg_per_week: profile.goal_rate_kg_per_week,
          diet_type: profile.diet_type,
          
          # Calculated values
          bmr_calories: profile.bmr_calories,
          tdee_calories: profile.tdee_calories,
          target_calories: profile.target_calories,
          
          # Macronutrient targets
          target_protein_g: profile.target_protein_g,
          target_carbs_g: profile.target_carbs_g,
          target_fat_g: profile.target_fat_g,
          
          # Macro percentages for reference
          macro_percentages: calculate_macro_percentages(profile),
          
          last_calculated_at: profile.last_calculated_at,
          created_at: profile.created_at,
          updated_at: profile.updated_at
        }
      end

      def calculate_macro_percentages(profile)
        return {} unless profile.target_calories && profile.target_calories > 0

        protein_calories = (profile.target_protein_g || 0) * 4
        carbs_calories = (profile.target_carbs_g || 0) * 4
        fat_calories = (profile.target_fat_g || 0) * 9
        
        {
          protein_percent: ((protein_calories.to_f / profile.target_calories) * 100).round(1),
          carbs_percent: ((carbs_calories.to_f / profile.target_calories) * 100).round(1),
          fat_percent: ((fat_calories.to_f / profile.target_calories) * 100).round(1)
        }
      end
    end
  end
end 