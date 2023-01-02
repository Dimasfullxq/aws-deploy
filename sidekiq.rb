# frozen_string_literal: true

require 'sidekiq/web'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || Rails.application.credentials.dig(:redis, :url) }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || Rails.application.credentials.dig(:redis, :url) }
end
