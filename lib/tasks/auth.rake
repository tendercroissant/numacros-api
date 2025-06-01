namespace :auth do
  desc "Clean up expired refresh tokens"
  task cleanup_expired_tokens: :environment do
    deleted_count = RefreshToken.cleanup_expired
    puts "Cleaned up #{deleted_count} expired refresh tokens"
  end
end 