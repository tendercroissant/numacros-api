require 'rails_helper'

RSpec.describe "Api::V1::EmailSubscriptions", type: :request do
  let(:valid_params) do
    {
      email_subscription: {
        email: 'test@example.com',
        name: 'Test User'
      }
    }
  end

  let(:admin_token) do
    verifier = ActiveSupport::MessageVerifier.new(
      Rails.application.secret_key_base,
      serializer: JSON
    )
    verifier.generate({
      admin: true,
      email: ENV["ADMIN_EMAIL"],
      exp: 1.hour.from_now.to_i
    })
  end

  let(:admin_headers) do
    { "Authorization" => "Bearer #{admin_token}" }
  end

  describe "POST /api/v1/email_subscriptions" do
    context "with valid parameters" do
      it "creates a new email subscription" do
        expect {
          post '/api/v1/email_subscriptions', params: valid_params
        }.to change(EmailSubscription, :count).by(1)
      end

      it "returns success message" do
        post '/api/v1/email_subscriptions', params: valid_params
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Successfully subscribed to email updates')
      end
    end

    context "with invalid parameters" do
      it "does not create subscription with invalid email" do
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

  describe "GET /api/v1/email_subscriptions" do
    let!(:subscription) { create(:email_subscription) }

    context "with valid admin token" do
      it "returns all subscriptions" do
        get '/api/v1/email_subscriptions', headers: admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).length).to eq(1)
      end
    end

    context "without admin token" do
      it "returns unauthorized" do
        get '/api/v1/email_subscriptions'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/email_subscriptions/:id" do
    let!(:subscription) { create(:email_subscription) }

    context "with valid admin token" do
      it "deletes the subscription" do
        expect {
          delete "/api/v1/email_subscriptions/#{subscription.id}", headers: admin_headers
        }.to change(EmailSubscription, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "without admin token" do
      it "returns unauthorized" do
        delete "/api/v1/email_subscriptions/#{subscription.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with non-existent id" do
      it "returns not found" do
        delete "/api/v1/email_subscriptions/999", headers: admin_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end 