require 'rails_helper'

RSpec.describe 'Api::V1::UserProfiles', type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  describe 'GET /api/v1/user_profile' do
    context 'when user has a profile' do
      let!(:user_profile) { create(:user_profile, user: user, name: 'John Doe', height_cm: 175.0) }

      it 'returns the user profile' do
        get '/api/v1/user_profile', headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('John Doe')
        expect(json['height_cm']).to eq('175.0')
        expect(json['age']).to be_present
        expect(json['height_m']).to eq("1.75")
      end
    end

    context 'when user has no profile' do
      it 'returns not found' do
        get '/api/v1/user_profile', headers: auth_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('User profile not found')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/user_profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/user_profile' do
    let(:valid_params) do
      {
        user_profile: {
          name: 'Jane Smith',
          birth_date: '1990-05-15',
          sex: 'female',
          height_cm: 165.5
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user profile' do
        expect {
          post '/api/v1/user_profile', params: valid_params, headers: auth_headers
        }.to change(UserProfile, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('Jane Smith')
        expect(json['sex']).to eq('female')
        expect(json['height_cm']).to eq('165.5')
      end
    end

    context 'when user already has a profile' do
      let!(:existing_profile) { create(:user_profile, user: user) }

      it 'returns unprocessable entity' do
        post '/api/v1/user_profile', params: valid_params, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('User profile already exists')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user_profile: {
            name: '',
            birth_date: '2030-01-01', # Future date
            sex: 'male',
            height_cm: 10.0 # Too short
          }
        }
      end

      it 'returns validation errors' do
        post '/api/v1/user_profile', params: invalid_params, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_an(Array)
        expect(json['errors']).to include(match(/name/i))
        expect(json['errors']).to include(match(/Birth date/i))
        expect(json['errors']).to include(match(/Height cm/i))
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        post '/api/v1/user_profile', params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/user_profile' do
    let!(:user_profile) { create(:user_profile, user: user, name: 'Original Name') }
    let(:update_params) do
      {
        user_profile: {
          name: 'Updated Name',
          height_cm: 180.0
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the user profile' do
        put '/api/v1/user_profile', params: update_params, headers: auth_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('Updated Name')
        expect(json['height_cm']).to eq('180.0')
        
        user_profile.reload
        expect(user_profile.name).to eq('Updated Name')
        expect(user_profile.height_cm).to eq(180.0)
      end
    end

    context 'when user has no profile' do
      before { user_profile.destroy }

      it 'returns not found' do
        put '/api/v1/user_profile', params: update_params, headers: auth_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('User profile not found')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user_profile: {
            name: '',
            height_cm: 500.0
          }
        }
      end

      it 'returns validation errors' do
        put '/api/v1/user_profile', params: invalid_params, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_an(Array)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        put '/api/v1/user_profile', params: update_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  private

  def generate_jwt_token(user)
    payload = { user_id: user.id, exp: 15.minutes.from_now.to_i }
    JWT.encode(payload, ENV.fetch('JWT_SECRET_KEY', 'test_secret'))
  end
end