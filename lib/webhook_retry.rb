# frozen_string_literal: true

require_relative "webhook_retry/version"
require_relative "webhook_retry/configuration"
require_relative "webhook_retry/services/dispatcher"

module WebhookRetry
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def enqueue(url:, payload:, headers: {}, max_attempts: nil, scheduled_at: nil, idempotency_key: nil, metadata: {})
      # Check for existing webhook with same idempotency key
      if idempotency_key.present?
        existing = Webhook.find_by(idempotency_key: idempotency_key)
        return existing if existing
      end

      endpoint = WebhookEndpoint.find_or_create_for_url(url)

      webhook = Webhook.create!(
        webhook_endpoint: endpoint,
        url: url,
        payload: payload,
        headers: headers,
        max_attempts: max_attempts || configuration.default_max_attempts,
        scheduled_at: scheduled_at,
        idempotency_key: idempotency_key,
        metadata: metadata
      )

      if scheduled_at.present?
        ProcessWebhookJob.set(wait_until: scheduled_at).perform_later(webhook.id)
      else
        ProcessWebhookJob.perform_later(webhook.id)
      end

      webhook
    end
  end
end

require_relative "webhook_retry/engine" if defined?(Rails::Engine)
