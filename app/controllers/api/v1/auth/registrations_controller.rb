module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        def create
          @user = User.new(auth_registration_params)

          if @user.save
            access_token = JwtService.generate_access_token(@user)
            refresh_token = @user.refresh_tokens.create!

            render json: {
              message: 'User created successfully',
              user: { id: @user.id, email: @user.email },
              access_token: access_token,
              refresh_token: refresh_token.token
            }, status: :created
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def auth_registration_params
          params.require(:auth_registration).permit(:email, :password, :password_confirmation)
        end
      end
    end
  end
end 