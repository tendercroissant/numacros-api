class Api::V1::Users::SettingsController < ApplicationController
  include Authenticatable

  def show
    setting = current_user.setting
    
    if setting.present?
      render json: {
        setting: {
          id: setting.id,
          unit_system: setting.unit_system,
          activity_level: setting.activity_level,
          weight_goal_type: setting.weight_goal_type,
          weight_goal_rate: setting.weight_goal_rate,
          diet_type: setting.diet_type,
          created_at: setting.created_at,
          updated_at: setting.updated_at
        }
      }
    else
      render json: {
        setting: nil,
        message: "No settings found for user"
      }
    end
  end

  def update
    setting = current_user.setting || current_user.build_setting

    begin
      if setting.update(setting_params)
        render json: {
          setting: {
            id: setting.id,
            unit_system: setting.unit_system,
            activity_level: setting.activity_level,
            weight_goal_type: setting.weight_goal_type,
            weight_goal_rate: setting.weight_goal_rate,
            diet_type: setting.diet_type,
            created_at: setting.created_at,
            updated_at: setting.updated_at
          }
        }
      else
        render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ArgumentError => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:setting).permit(
      :unit_system,
      :activity_level,
      :weight_goal_type,
      :weight_goal_rate,
      :diet_type
    )
  end
end 