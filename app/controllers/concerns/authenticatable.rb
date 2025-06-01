module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = extract_token_from_header
    return render_unauthorized unless token

    payload = JwtService.decode(token)
    return render_unauthorized unless payload

    @current_user = User.find(payload['user_id'])
  rescue ActiveRecord::RecordNotFound
    render_unauthorized
  end

  def current_user
    @current_user
  end

  def extract_token_from_header
    authorization_header = request.headers['Authorization']
    return nil unless authorization_header

    authorization_header.split(' ').last if authorization_header.starts_with?('Bearer ')
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end 