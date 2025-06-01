require 'rails_helper'

RSpec.describe "Auth::Tokens", type: :request do
  let(:user) { create(:user) }
  
  describe "POST /auth/refresh_token" do
    context "with valid refresh token" do
      let(:refresh_token) { create(:refresh_token, user: user) }
      
      it "returns new access token" do
        post "/auth/refresh_token", params: { refresh_token: refresh_token.token }, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['access_token']).to be_present
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
      end

      it "returns valid JWT access token" do
        post "/auth/refresh_token", params: { refresh_token: refresh_token.token }, as: :json
        json_response = JSON.parse(response.body)
        
        decoded_token = JwtService.decode(json_response['access_token'])
        expect(decoded_token['user_id']).to eq(user.id)
      end
    end

    context "with invalid refresh token" do
      it "returns unauthorized for non-existent token" do
        post "/auth/refresh_token", params: { refresh_token: "invalid-token" }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid or expired refresh token')
      end

      it "returns unauthorized for expired token" do
        expired_token = create(:refresh_token, user: user, expires_at: 1.hour.ago)
        post "/auth/refresh_token", params: { refresh_token: expired_token.token }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid or expired refresh token')
      end

      it "returns unauthorized when no token provided" do
        post "/auth/refresh_token", params: {}, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid or expired refresh token')
      end
    end
  end

  describe "DELETE /auth/logout_all" do
    let(:access_token) { JwtService.generate_access_token(user) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{access_token}" } }

    context "with valid authentication" do
      before do
        create_list(:refresh_token, 3, user: user)
      end

      it "deletes all refresh tokens for the user" do
        expect {
          delete "/auth/logout_all", headers: auth_headers, as: :json
        }.to change { user.refresh_tokens.count }.from(3).to(0)
      end

      it "returns success message" do
        delete "/auth/logout_all", headers: auth_headers, as: :json
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Logged out from all devices successfully')
      end

      it "does not affect other users' tokens" do
        other_user = create(:user)
        other_user_token = create(:refresh_token, user: other_user)
        
        delete "/auth/logout_all", headers: auth_headers, as: :json
        
        expect(RefreshToken.exists?(other_user_token.id)).to be true
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        delete "/auth/logout_all", as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context "with invalid token" do
      it "returns unauthorized" do
        delete "/auth/logout_all", headers: { 'Authorization' => "Bearer invalid-token" }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end
end 