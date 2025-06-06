class User < ApplicationRecord
  has_secure_password
  has_many :refresh_tokens, dependent: :destroy

  validates :email, presence: true, email: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 8 }, on: :create

  def generate_tokens(ip_address: nil, user_agent: nil)
    {
      access_token: generate_access_token,
      refresh_token: generate_refresh_token(ip_address: ip_address, user_agent: user_agent)
    }
  end

  def refresh_access_token
    generate_access_token
  end

  def revoke_refresh_token(reason: nil, ip_address: nil)
    refresh_tokens.active.each do |token|
      token.revoke!(reason: reason, ip_address: ip_address)
    end
  end

  def revoke_all_refresh_tokens(reason: "user_logout_all", ip_address: nil)
    refresh_tokens.active.each do |token|
      token.revoke!(reason: reason, ip_address: ip_address)
    end
  end

  private

  def generate_access_token
    payload = {
      user_id: id,
      exp: 15.minutes.from_now.to_i
    }
    JWT.encode(payload, jwt_secret_key)
  end

  def generate_refresh_token(ip_address: nil, user_agent: nil)
    # Revoke any existing active tokens (optional - for single-session approach)
    # refresh_tokens.active.update_all(status: :replaced)
    
    token_string = SecureRandom.hex(32)
    hashed_token = BCrypt::Password.create(token_string)
    
    refresh_tokens.create!(
      token: hashed_token,
      expires_at: 30.days.from_now,
      status: :active,
      issued_from_ip: ip_address,
      user_agent: user_agent
    )
    
    token_string
  end

  def jwt_secret_key
    ENV.fetch('JWT_SECRET_KEY') do
      raise 'JWT_SECRET_KEY environment variable is not set'
    end
  end
end 