class Api::V1::ProfileController < ApplicationController
  include Authenticatable

  def show
    profile_data = if current_user.user_profile.present?
      profile = current_user.user_profile
      
      profile_json = {
        id: profile.id,
        name: profile.name,
        birth_date: profile.birth_date,
        gender: profile.gender,
        weight_kg: profile.weight_kg,
        height_cm: profile.height_cm,
        unit_system: profile.unit_system,
        activity_level: profile.activity_level,
        weight_goal_type: profile.weight_goal_type,
        weight_goal_rate: profile.weight_goal_rate,
        dietary_type: profile.dietary_type,
        custom_carbs_percent: profile.custom_carbs_percent,
        custom_protein_percent: profile.custom_protein_percent,
        custom_fat_percent: profile.custom_fat_percent,
        calculations: {
          age: profile.age,
          bmr: profile.bmr,
          tdee: profile.tdee,
          calorie_goal: profile.calorie_goal
        },
        macronutrients: profile.macronutrients
      }
      
      # Add persisted macronutrient target data
      if profile.macronutrient_target.present?
        target = profile.macronutrient_target
        profile_json[:macronutrient_target] = {
          calories: target.calories,
          carbs_grams: target.carbs_grams,
          protein_grams: target.protein_grams,
          fat_grams: target.fat_grams,
          updated_at: target.updated_at
        }
      else
        profile_json[:macronutrient_target] = nil
      end
      
      # Add imperial display if user prefers imperial
      if profile.unit_system == 'imperial'
        profile_json[:imperial_display] = {
          weight_lbs: UserProfile.kg_to_pounds(profile.weight_kg).round(1),
          height_feet_inches: UserProfile.cm_to_feet_inches(profile.height_cm)
        }
      end
      
      profile_json
    else
      nil
    end

    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        profile: profile_data
      }
    }
  end

  def update
    profile = current_user.user_profile || current_user.build_user_profile

    # Handle imperial input conversion
    profile_params_converted = convert_imperial_if_needed(profile_params)
    
    if profile.update(profile_params_converted)
      show # Reuse show logic to return updated profile
    else
      render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:profile).permit(
      :name, :birth_date, :gender, :weight_kg, :height_cm, :unit_system,
      :activity_level, :weight_goal_type, :weight_goal_rate, :dietary_type,
      :custom_carbs_percent, :custom_protein_percent, :custom_fat_percent,
      # Imperial input fields
      :weight, :height_feet, :height_inches
    )
  end

  def convert_imperial_if_needed(params)
    converted_params = params.dup

    # Convert imperial weight to metric
    if params[:weight].present?
      converted_params[:weight_kg] = UserProfile.pounds_to_kg(params[:weight].to_f)
      converted_params.delete(:weight)
    end

    # Convert imperial height to metric
    if params[:height_feet].present? && params[:height_inches].present?
      converted_params[:height_cm] = UserProfile.feet_inches_to_cm(
        params[:height_feet].to_i, 
        params[:height_inches].to_i
      ).round
      converted_params.delete(:height_feet)
      converted_params.delete(:height_inches)
    end

    converted_params
  end
end
