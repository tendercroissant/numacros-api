# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.development?
      origins 'http://localhost:3000'
    else
      origins 'https://numacros.com'
    end

    # Admin authentication endpoint
    resource '/admin/login',
      headers: :any,
      methods: [:post, :options],
      credentials: true

    # Email subscription endpoints
    resource '/api/v1/email_subscriptions*',
      headers: :any,
      methods: [:get, :post, :delete, :options],
      credentials: true
  end
end
