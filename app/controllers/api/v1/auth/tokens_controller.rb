module Api
  module V1
    module Auth
      class TokensController < ApplicationController
        include Authenticatable
        
        skip_before_action :authenticate_user!, only: [:refresh_token]

        def refresh_token
          refresh_token = params[:refresh_token]
          return render_invalid_token unless refresh_token

          token_record = RefreshToken.valid_tokens.find_by(token: refresh_token)
          return render_invalid_token unless token_record

          user = token_record.user
          new_access_token = JwtService.generate_access_token(user)

          render json: {
            access_token: new_access_token,
            user: { id: user.id, email: user.email }
          }, status: :ok
        end

        def logout_all
          current_user.refresh_tokens.destroy_all
          render json: { message: 'Logged out from all devices successfully' }, status: :ok
        end

        private

        def render_invalid_token
          render json: { error: 'Invalid or expired refresh token' }, status: :unauthorized
        end
      end
    end
  end
end 