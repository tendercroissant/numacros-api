# frozen_string_literal: true

# Load admin credentials from environment variables
# Fails fast if credentials are missing
Rails.application.config.admin_email = ENV.fetch("ADMIN_EMAIL")
Rails.application.config.admin_password = ENV.fetch("ADMIN_PASSWORD") 