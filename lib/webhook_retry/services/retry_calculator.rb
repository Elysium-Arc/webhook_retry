# frozen_string_literal: true

module WebhookRetry
  class RetryCalculator
    def next_retry_delay(attempt:)
      base = config.retry_base_delay
      max = config.max_retry_delay
      jitter_factor = config.retry_jitter_factor

      # Exponential backoff: base * 2^(attempt-1)
      exponential_delay = base * (2**(attempt - 1))

      # Cap at max delay
      capped_delay = [exponential_delay, max].min

      # Add jitter: random value between 0 and jitter_factor * delay
      jitter = (rand * jitter_factor * capped_delay).to_i

      capped_delay + jitter
    end

    def next_retry_at(attempt:)
      Time.current + next_retry_delay(attempt: attempt).seconds
    end

    private

    def config
      WebhookRetry.configuration
    end
  end
end
