# frozen_string_literal: true

module WebhookRetry
  class Configuration
    attr_accessor :job_queue,
                  :http_open_timeout,
                  :http_read_timeout,
                  :default_max_attempts,
                  :success_codes,
                  # Phase 2: Retry configuration
                  :retry_base_delay,
                  :max_retry_delay,
                  :retry_jitter_factor,
                  # Phase 2: Circuit breaker configuration
                  :circuit_breaker_threshold,
                  :circuit_breaker_timeout,
                  :circuit_breaker_enabled

    def initialize
      @job_queue = :webhooks
      @http_open_timeout = 5
      @http_read_timeout = 30
      @default_max_attempts = 5
      @success_codes = (200..299).to_a

      # Phase 2: Retry defaults
      @retry_base_delay = 60          # 1 minute base delay
      @max_retry_delay = 3600         # 1 hour max delay
      @retry_jitter_factor = 0.5      # Up to 50% random jitter

      # Phase 2: Circuit breaker defaults
      @circuit_breaker_threshold = 5  # failures before opening
      @circuit_breaker_timeout = 300  # 5 minutes cooldown
      @circuit_breaker_enabled = true
    end
  end
end
