require 'rails_helper'

RSpec.describe 'Api::V1::EmailSubscriptions', type: :request do
  describe 'POST /api/v1/email_subscriptions' do
    let(:valid_params) do
      {
        email_subscription: {
          email: 'test@example.com',
          name: 'Test User'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new email subscription' do
        expect {
          post '/api/v1/email_subscriptions', params: valid_params
        }.to change(EmailSubscription, :count).by(1)
      end

      it 'returns success message' do
        post '/api/v1/email_subscriptions', params: valid_params
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Successfully subscribed to email updates')
      end
    end

    context 'with invalid parameters' do
      it 'does not create subscription with invalid email' do
        invalid_params = valid_params.deep_dup
        invalid_params[:email_subscription][:email] = 'invalid-email'

        expect {
          post '/api/v1/email_subscriptions', params: invalid_params
        }.not_to change(EmailSubscription, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create duplicate subscriptions' do
        create(:email_subscription, email: 'test@example.com')

        expect {
          post '/api/v1/email_subscriptions', params: valid_params
        }.not_to change(EmailSubscription, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end 