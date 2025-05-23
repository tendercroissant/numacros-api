require "test_helper"

class Api::V1::EmailSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_v1_email_subscriptions_create_url
    assert_response :success
  end
end 