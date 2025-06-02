class JsonWebToken
  def self.encode(payload)
    # If the payload contains user_id, create a User object and generate token
    if payload[:user_id]
      user = User.find(payload[:user_id])
      JwtService.generate_access_token(user)
    else
      # For other payloads, use JwtService.encode directly
      JwtService.encode(payload)
    end
  end

  def self.decode(token)
    JwtService.decode(token)
  end
end 