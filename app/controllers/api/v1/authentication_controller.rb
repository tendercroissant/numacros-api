module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authenticate_user, only: [:register, :login]

      def register
        User.transaction do
          # Create user first with just basic params (no nested attributes yet)
          user = User.new(basic_user_params)
          
          if user.save
            errors = []
            
            # Create weight first (required for nutrition profile validation)
            if weight_params.present?
              weight = user.weights.build(
                weight_kg: weight_params[:weight_kg],
                recorded_at: weight_params[:recorded_at] || Time.current
              )
              unless weight.save
                errors += weight.errors.full_messages
              end
            end
            
            # Create user profile if provided
            if user_profile_params.present?
              user_profile = user.build_user_profile(user_profile_params)
              unless user_profile.save
                errors += user_profile.errors.full_messages
              end
            end
            
            # Create nutrition profile if provided (after weight exists)
            if nutrition_profile_params.present?
              nutrition_profile = user.build_nutrition_profile(nutrition_profile_params)
              unless nutrition_profile.save
                errors += nutrition_profile.errors.full_messages
              end
            end
            
            # If any errors occurred, rollback
            if errors.any?
              raise ActiveRecord::Rollback
            end
            
            tokens = user.generate_tokens(
              ip_address: request.remote_ip,
              user_agent: request.user_agent
            )
            
            # Include calculated nutrition data in response
            response_data = { tokens: tokens }
            
            if user.nutrition_profile.present?
              response_data[:nutrition_profile] = {
                id: user.nutrition_profile.id,
                current_weight: user.nutrition_profile.current_weight,
                activity_level: user.nutrition_profile.activity_level,
                goal: user.nutrition_profile.goal,
                rate: user.nutrition_profile.rate,
                diet_type: user.nutrition_profile.diet_type,
                bmr: user.nutrition_profile.bmr,
                tdee: user.nutrition_profile.tdee,
                target_calories: user.nutrition_profile.target_calories,
                target_protein_g: user.nutrition_profile.target_protein_g,
                target_carbs_g: user.nutrition_profile.target_carbs_g,
                target_fat_g: user.nutrition_profile.target_fat_g,
                calculated_at: user.nutrition_profile.calculated_at
              }
            end
            
            render json: response_data, status: :created
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::Rollback
        render json: { errors: errors }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      def login
        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
          tokens = user.generate_tokens(
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )
          render json: { tokens: tokens }
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def refresh
        refresh_token = request.headers['X-Refresh-Token']
        if refresh_token && JwtService.valid_refresh_token?(@current_user, refresh_token)
          render json: { access_token: @current_user.refresh_access_token }
        else
          render json: { error: 'Invalid refresh token' }, status: :unauthorized
        end
      end

      def logout
        @current_user.revoke_refresh_token(
          reason: "user_logout",
          ip_address: request.remote_ip
        )
        head :no_content
      end

      def logout_all
        @current_user.revoke_all_refresh_tokens(
          reason: "user_logout_all",
          ip_address: request.remote_ip
        )
        head :no_content
      end

      private

      def user_params
        # Start with basic user params
        user_data = params.require(:user).permit(:email, :password, :password_confirmation)
        
        # Handle user_profile nested attributes
        if params[:user][:user_profile].present?
          user_profile_data = params.require(:user).require(:user_profile).permit(:name, :sex, :birth_date, :height_cm)
          
          # Set default name if not provided
          unless user_profile_data[:name].present?
            user_profile_data[:name] = user_data[:email].split('@').first.humanize
          end
          
          user_data[:user_profile_attributes] = user_profile_data
        end
        
                 # Handle nutrition_profile nested attributes
         if params[:user][:nutrition_profile].present?
           nutrition_profile_data = params.require(:user).require(:nutrition_profile).permit(:goal, :activity_level, :diet_type, :rate)
           
           # Default rate based on goal (always positive, goal determines deficit/surplus)
           unless nutrition_profile_data[:rate].present?
             case nutrition_profile_data[:goal]
             when 'lose_weight'
               nutrition_profile_data[:rate] = 0.5   # 0.5 kg/week weight loss
             when 'gain_muscle'
               nutrition_profile_data[:rate] = 0.25  # 0.25 kg/week muscle gain
             else # maintain
               nutrition_profile_data[:rate] = 0.0   # maintain current weight
             end
           end
           
           # Default diet_type to balanced
           nutrition_profile_data[:diet_type] ||= 'balanced'
           
           user_data[:nutrition_profile_attributes] = nutrition_profile_data
         end
        
        user_data
      end

      def weight_params
        return nil unless params.dig(:user, :weight)
        params.require(:user).require(:weight).permit(:weight_kg, :recorded_at)
      end

      def basic_user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end

      def user_profile_params
        return nil unless params.dig(:user, :user_profile)
        user_profile_data = params.require(:user).require(:user_profile).permit(:name, :sex, :birth_date, :height_cm)
        
        # Set default name if not provided
        unless user_profile_data[:name].present?
          user_profile_data[:name] = params[:user][:email].split('@').first.humanize
        end
        
        user_profile_data
      end

      def nutrition_profile_params
        return nil unless params.dig(:user, :nutrition_profile)
        nutrition_profile_data = params.require(:user).require(:nutrition_profile).permit(:goal, :activity_level, :diet_type, :rate)
        
        # Default rate based on goal (always positive, goal determines deficit/surplus)
        unless nutrition_profile_data[:rate].present?
          case nutrition_profile_data[:goal]
          when 'lose_weight'
            nutrition_profile_data[:rate] = 0.5   # 0.5 kg/week weight loss
          when 'gain_muscle'
            nutrition_profile_data[:rate] = 0.25  # 0.25 kg/week muscle gain
          else # maintain
            nutrition_profile_data[:rate] = 0.0   # maintain current weight
          end
        end
        
        # Default diet_type to balanced
        nutrition_profile_data[:diet_type] ||= 'balanced'
        
        nutrition_profile_data
      end
    end
  end
end 