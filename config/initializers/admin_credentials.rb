# frozen_string_literal: true

# Load admin credentials from environment variables
# Use ENV[] instead of ENV.fetch to avoid crashing when env vars are missing
Rails.application.config.admin_email = ENV["ADMIN_EMAIL"] || "admin@example.com"
Rails.application.config.admin_password = ENV["ADMIN_PASSWORD"] || "password" 