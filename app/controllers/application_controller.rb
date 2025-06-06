class ApplicationController < ActionController::API
  before_action :authenticate_user

  private

  def authenticate_user
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    payload = JwtService.decode_token(token)

    if payload
      @current_user = User.find_by(id: payload['user_id'])
      render json: { error: 'User not found' }, status: :unauthorized unless @current_user
    else
      render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end
  end
end
