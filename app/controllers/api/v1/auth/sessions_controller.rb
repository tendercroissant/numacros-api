module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        def create
          @user = User.find_by(email: login_params[:email]&.downcase&.strip)

          if @user&.authenticate(login_params[:password])
            access_token = JwtService.generate_access_token(@user)
            refresh_token = @user.refresh_tokens.create!

            render json: {
              message: 'Logged in successfully',
              user: { id: @user.id, email: @user.email },
              access_token: access_token,
              refresh_token: refresh_token.token
            }, status: :ok
          else
            render json: { error: 'Invalid credentials' }, status: :unauthorized
          end
        end

        private

        def login_params
          params.require(:user).permit(:email, :password)
        end
      end
    end
  end
end 