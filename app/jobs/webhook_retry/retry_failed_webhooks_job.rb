# frozen_string_literal: true

module WebhookRetry
  class RetryFailedWebhooksJob < ApplicationJob
    queue_as { WebhookRetry.configuration.job_queue }

    def perform
      webhooks_ready_for_retry.find_each do |webhook|
        circuit_breaker = CircuitBreaker.new(webhook.webhook_endpoint)
        next unless circuit_breaker.allow_request?

        webhook.update!(scheduled_at: nil)
        ProcessWebhookJob.perform_later(webhook.id)
      end
    end

    private

    def webhooks_ready_for_retry
      Webhook
        .where(status: "failed")
        .where("attempt_count < max_attempts")
        .where(scheduled_at: ..Time.current)
    end
  end
end
