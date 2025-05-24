module AdminAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_admin!
  end

  private

  def authenticate_admin!
    token = request.headers["Authorization"]&.split("Bearer ")&.last
    return head :unauthorized unless token

    payload = verifier.verify(token)

    if payload["admin"] && Time.at(payload["exp"]) > Time.now
      # authenticated
    else
      head :unauthorized
    end
  rescue
    head :unauthorized
  end

  def verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(
      Rails.application.secret_key_base,
      serializer: JSON
    )
  end
end 