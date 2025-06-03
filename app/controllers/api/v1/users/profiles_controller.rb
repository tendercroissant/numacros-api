class Api::V1::Users::ProfilesController < ApplicationController
  include Authenticatable

  def show
    profile_data = if current_user.profile.present?
      profile = current_user.profile
      setting = current_user.setting
      
      profile_json = {
        id: profile.id,
        name: profile.name,
        birth_date: profile.birth_date,
        gender: profile.gender,
        height_cm: profile.height_cm,
        calculations: {
          age: profile.age,
          bmr: profile.bmr,
          tdee: profile.tdee,
          calorie_goal: profile.calorie_goal
        },
        macronutrients: profile.macronutrients
      }

      # Add setting fields if setting exists
      if setting.present?
        profile_json.merge!(
          unit_system: setting.unit_system,
          activity_level: setting.activity_level,
          weight_goal_type: setting.weight_goal_type,
          weight_goal_rate: setting.weight_goal_rate,
          diet_type: setting.diet_type
        )
      end
      
      # Add imperial display if user prefers imperial
      if setting&.unit_system == 'imperial'
        profile_json[:imperial_display] = imperial_converted_response(profile)
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
    profile = current_user.profile || current_user.build_profile
    setting = current_user.setting || current_user.build_setting

    # Handle imperial input conversion
    profile_params_converted = convert_imperial_params(profile_params)
    
    # Split params between profile and setting
    setting_fields = [:unit_system, :activity_level, :weight_goal_type, :weight_goal_rate, :diet_type]
    profile_fields = profile_params_converted.except(*setting_fields)
    setting_params = profile_params_converted.slice(*setting_fields)

    # Update both models in a transaction
    ActiveRecord::Base.transaction do
      if setting_params.present? && !setting.update(setting_params)
        render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
        return
      end

      if profile_fields.present? && !profile.update(profile_fields)
        render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
        return
      end
    end

    show # Reuse show logic to return updated profile
  end

  private

  def profile_params
    params.require(:profile).permit(
      :name, :birth_date, :gender, :height_cm, :unit_system,
      :activity_level, :weight_goal_type, :weight_goal_rate, :diet_type,
      # Imperial input fields
      :height_feet, :height_inches
    )
  end

  def convert_imperial_params(params)
    converted_params = params.dup

    # Handle weight conversion
    if params[:weight_lbs].present?
      converted_params[:weight_kg] = Profile.pounds_to_kg(params[:weight_lbs].to_f)
      converted_params.delete(:weight_lbs)
    end

    # Handle height conversion
    if params[:height_feet].present? && params[:height_inches].present?
      converted_params[:height_cm] = Profile.feet_inches_to_cm(
        params[:height_feet].to_i, 
        params[:height_inches].to_i
      )
      converted_params.delete(:height_feet)
      converted_params.delete(:height_inches)
    end

    converted_params
  end

  # Imperial unit conversion for response
  def imperial_converted_response(profile)
    profile.as_json.merge(
      weight_lbs: Profile.kg_to_pounds(profile.weight_kg).round(1),
      height_feet_inches: Profile.cm_to_feet_inches(profile.height_cm)
    )
  end
end 