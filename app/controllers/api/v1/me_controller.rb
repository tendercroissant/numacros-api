module Api
  module V1
    class MeController < ApplicationController
      def show
        render json: {
          id: @current_user.id,
          email: @current_user.email,
          created_at: @current_user.created_at
        }
      end
    end
  end
end 