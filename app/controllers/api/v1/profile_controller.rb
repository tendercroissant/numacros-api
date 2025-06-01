class Api::V1::ProfileController < ApplicationController
  include Authenticatable

  def show
    profile = current_user.user_profile
    
    if profile
      render json: {
        user: {
          id: current_user.id,
          email: current_user.email,
          profile: {
            name: profile.name,
            birth_date: profile.birth_date
          }
        }
      }, status: :ok
    else
      render json: {
        user: {
          id: current_user.id,
          email: current_user.email,
          profile: nil
        }
      }, status: :ok
    end
  end

  def update
    profile = current_user.user_profile || current_user.build_user_profile

    if profile.update(profile_params)
      render json: {
        message: 'Profile updated successfully',
        user: {
          id: current_user.id,
          email: current_user.email,
          profile: {
            name: profile.name,
            birth_date: profile.birth_date
          }
        }
      }, status: :ok
    else
      render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:name, :birth_date)
  end
end
