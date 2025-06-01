class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base

  def self.encode(payload)
    payload[:exp] = 15.minutes.from_now.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })
    decoded[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    nil
  end

  def self.generate_access_token(user)
    encode({ user_id: user.id })
  end
end 