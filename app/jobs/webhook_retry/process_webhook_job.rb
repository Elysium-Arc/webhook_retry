# frozen_string_literal: true

module WebhookRetry
  class ProcessWebhookJob < ApplicationJob
    queue_as { WebhookRetry.configuration.job_queue }

    def perform(webhook_id)
      @webhook = Webhook.find_by(id: webhook_id)
      return unless @webhook&.deliverable?

      @circuit_breaker = CircuitBreaker.new(@webhook.webhook_endpoint)

      # Check circuit breaker before attempting delivery
      unless @circuit_breaker.allow_request?
        schedule_retry_for_circuit_breaker
        return
      end

      @webhook.mark_processing!
      @webhook.increment_attempt!

      result = Dispatcher.new(@webhook).call
      record_attempt(result)
      handle_result(result)
    end

    private

    def handle_result(result)
      if result.success?
        handle_success
      else
        handle_failure(result)
      end
    end

    def handle_success
      @webhook.mark_delivered!
      @circuit_breaker.record_success
    end

    def handle_failure(result)
      @circuit_breaker.record_failure

      classifier = ErrorClassifier.new(result)

      if classifier.permanent_failure?
        mark_as_dead
      else
        mark_as_failed_and_schedule_retry
      end
    end

    def mark_as_dead
      @webhook.update!(status: "dead", failed_at: Time.current)
    end

    def mark_as_failed_and_schedule_retry
      @webhook.mark_failed!
      RetryScheduler.new(@webhook).schedule_retry
    end

    def schedule_retry_for_circuit_breaker
      # Schedule retry for when circuit breaker might be half-open
      timeout = WebhookRetry.configuration.circuit_breaker_timeout
      @webhook.update!(scheduled_at: Time.current + timeout.seconds)
    end

    def record_attempt(result)
      WebhookAttempt.record!(
        webhook: @webhook,
        attempt_number: @webhook.attempt_count,
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
