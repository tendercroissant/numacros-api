require 'rails_helper'

RSpec.describe Api::V1::MeController, type: :controller do
  describe 'GET #show' do
    let(:user) { create(:user, email: 'test@example.com') }
    let(:tokens) { user.generate_tokens }

    context 'with valid access token' do
      before do
        request.headers['Authorization'] = "Bearer #{tokens[:access_token]}"
      end

      it 'returns current user information' do
        get :show
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(user.id)
        expect(json_response['email']).to eq(user.email)
        expect(json_response['created_at']).to be_present
      end

      it 'returns user information in correct format' do
        get :show
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response.keys).to contain_exactly('id', 'email', 'created_at')
      end
    end

    context 'without access token' do
      it 'returns unauthorized status' do
        get :show
        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid or expired token')
      end
    end

    context 'with invalid access token' do
      before do
        request.headers['Authorization'] = "Bearer invalid_token"
      end

      it 'returns unauthorized status' do
        get :show
        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid or expired token')
      end
    end
  end
end 