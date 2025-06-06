require 'rails_helper'

RSpec.describe "Admin::Sessions", type: :request do
  let(:admin_email) { ENV["ADMIN_EMAIL"] }
  let(:admin_password) { ENV["ADMIN_PASSWORD"] }

  let(:valid_credentials) do
    {
      email: admin_email,
      password: admin_password
    }
  end

  let(:invalid_credentials) do
    {
      email: "wrong@example.com",
      password: "wrongpassword"
    }
  end

  describe "POST /admin/login" do
    context "with valid credentials" do
      it "returns a token" do
        post "/admin/login", params: valid_credentials
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to have_key("token")
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized status" do
        post "/admin/login", params: invalid_credentials
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ "error" => "Invalid or expired token" })
      end
    end

    context "with missing credentials" do
      it "returns unauthorized status" do
        post "/admin/login", params: {}
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ "error" => "Invalid or expired token" })
      end
    end
  end
end 