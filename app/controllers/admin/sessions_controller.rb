module Admin
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user, only: [:create]
    
    def create
      if authenticate_admin
        token = generate_admin_token
        render json: { token: token }, status: :ok
      else
        render json: { error: "Invalid or expired token" }, status: :unauthorized
      end
    end

    private

    def authenticate_admin
      email_match = ENV["ADMIN_EMAIL"].strip == params[:email].to_s.strip
      password_match = ENV["ADMIN_PASSWORD"].strip == params[:password].to_s.strip
      email_match && password_match
    end

    def generate_admin_token
      payload = {
        admin: true,
        email: ENV["ADMIN_EMAIL"],
        exp: 1.hour.from_now.to_i
      }

      verifier = ActiveSupport::MessageVerifier.new(
        Rails.application.secret_key_base,
        serializer: JSON
      )

      verifier.generate(payload)
    end
  end
end 