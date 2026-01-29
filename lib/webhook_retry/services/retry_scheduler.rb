# frozen_string_literal: true

module WebhookRetry
  class RetryScheduler
    def initialize(webhook)
      @webhook = webhook
    end

    def schedule_retry
      return false unless retryable?

      next_attempt = @webhook.attempt_count + 1
      retry_at = calculator.next_retry_at(attempt: next_attempt)

      @webhook.update!(scheduled_at: retry_at)
      true
    end

    def retryable?
      @webhook.status == "failed" && @webhook.attempt_count < @webhook.max_attempts
    end

    def self.schedule_all_pending_retries
      webhooks = Webhook.where(status: "failed", scheduled_at: nil)
        .where("attempt_count < max_attempts")

      count = 0
      webhooks.find_each do |webhook|
        scheduler = new(webhook)
        count += 1 if scheduler.schedule_retry
      end
      count
    end

    private

    def calculator
      @calculator ||= RetryCalculator.new
    end
  end
end
