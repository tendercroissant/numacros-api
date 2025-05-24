module Admin
  class SessionsController < ApplicationController
    def create
      if authenticate_admin
        token = generate_admin_token
        render json: { token: token }, status: :ok
      else
        render json: { error: "Invalid credentials" }, status: :unauthorized
      end
    end

    private

    def authenticate_admin
      email_match = ActiveSupport::SecurityUtils.secure_compare(
        Rails.application.config.admin_email,
        params[:email].to_s
      )

      password_match = ActiveSupport::SecurityUtils.secure_compare(
        Rails.application.config.admin_password,
        params[:password].to_s
      )

      email_match && password_match
    end

    def generate_admin_token
      payload = {
        admin: true,
        email: Rails.application.config.admin_email,
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