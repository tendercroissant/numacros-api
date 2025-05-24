require 'rails_helper'

RSpec.describe "Admin::Sessions", type: :request do
  let(:admin_email) { "admin@example.com" }
  let(:admin_password) { "supersecret" }

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

  before do
    stub_const("ENV", ENV.to_hash.merge(
      "ADMIN_EMAIL" => admin_email,
      "ADMIN_PASSWORD" => admin_password
    ))
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
        expect(JSON.parse(response.body)).to eq({ "error" => "Invalid credentials" })
      end
    end

    context "with missing credentials" do
      it "returns unauthorized status" do
        post "/admin/login", params: {}
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ "error" => "Invalid credentials" })
      end
    end
  end
end 