module Api
  module V1
    class UserProfilesController < ApplicationController
      before_action :set_user_profile, only: [:show, :update]

      def show
        if @user_profile
          render json: user_profile_json(@user_profile)
        else
          render json: { error: 'User profile not found' }, status: :not_found
        end
      end

      def create
        if @current_user.user_profile.present?
          return render json: { error: 'User profile already exists' }, status: :unprocessable_entity
        end

        @user_profile = @current_user.build_user_profile(user_profile_params)

        if @user_profile.save
          render json: user_profile_json(@user_profile), status: :created
        else
          render json: { errors: @user_profile.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        unless @user_profile
          return render json: { error: 'User profile not found' }, status: :not_found
        end

        if @user_profile.update(user_profile_params)
          render json: user_profile_json(@user_profile)
        else
          render json: { errors: @user_profile.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_user_profile
        @user_profile = @current_user.user_profile
      end

      def user_profile_params
        params.require(:user_profile).permit(:name, :birth_date, :sex, :height_cm)
      end

      def user_profile_json(profile)
        {
          id: profile.id,
          name: profile.name,
          birth_date: profile.birth_date,
          sex: profile.sex,
          height_cm: profile.height_cm,
          age: profile.age,
          height_m: profile.height_m,
          bmi: profile.bmi,
          bmi_category: profile.bmi_category,
          created_at: profile.created_at,
          updated_at: profile.updated_at
        }
      end
    end
  end
end 