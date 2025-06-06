module AdminAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_admin!
  end

  private

  def authenticate_admin!
    token = request.headers["Authorization"]&.split("Bearer ")&.last
    return render json: { error: "Invalid or expired token" }, status: :unauthorized unless token

    payload = verifier.verify(token)

    if payload["admin"] && payload["email"] == ENV["ADMIN_EMAIL"] && Time.at(payload["exp"]) > Time.now
      # authenticated
    else
      render json: { error: "Invalid or expired token" }, status: :unauthorized
    end
  rescue
    render json: { error: "Invalid or expired token" }, status: :unauthorized
  end

  def verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(
      Rails.application.secret_key_base,
      serializer: JSON
    )
  end
end 