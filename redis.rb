# frozen_string_literal: true

class CurrentRedis
  class << self
    attr_accessor :client
  end
end

CurrentRedis.client =
  Rails.env.test? ? MockRedis.new : Redis.new(url: ENV['REDIS_URL'] || Rails.application.credentials.dig(:redis, :url))
