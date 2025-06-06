class JwtService
  class << self
    def decode_token(token)
      JWT.decode(token, jwt_secret_key)[0]
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    def valid_refresh_token?(user, token_string)
      !!user.refresh_tokens.active.find do |refresh_token|
        refresh_token.still_valid? && BCrypt::Password.new(refresh_token.token).is_password?(token_string)
      end
    end

    private

    def jwt_secret_key
      ENV.fetch('JWT_SECRET_KEY') do
        raise 'JWT_SECRET_KEY environment variable is not set'
      end
    end
  end
end 