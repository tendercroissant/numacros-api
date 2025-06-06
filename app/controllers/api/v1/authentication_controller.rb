module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authenticate_user, only: [:register, :login]

      def register
        user = User.new(user_params)
        if user.save
          tokens = user.generate_tokens(
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )
          render json: { tokens: tokens }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
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
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end 