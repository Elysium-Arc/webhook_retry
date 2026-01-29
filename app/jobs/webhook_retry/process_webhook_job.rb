# frozen_string_literal: true

module WebhookRetry
  class ProcessWebhookJob < ApplicationJob
    queue_as { WebhookRetry.configuration.job_queue }

    def perform(webhook_id)
      webhook = Webhook.find_by(id: webhook_id)
      return unless webhook&.deliverable?

      webhook.mark_processing!
      webhook.increment_attempt!

      result = Dispatcher.new(webhook).call

      record_attempt(webhook, result)

      if result.success?
        webhook.mark_delivered!
        webhook.webhook_endpoint.record_success!
      else
        webhook.mark_failed!
        webhook.webhook_endpoint.record_failure!
      end
    end

    private

    def record_attempt(webhook, result)
      WebhookAttempt.record!(
        webhook: webhook,
        attempt_number: webhook.attempt_count,
        response_status: result.status,
        response_body: result.body,
        response_headers: result.headers || {},
        duration_ms: result.duration_ms,
        success: result.success?,
        error_class: result.error&.class&.name,
        error_message: result.error&.message
      )
    end
  end
end
