# frozen_string_literal: true

module WebhookRetry
  class Configuration
    attr_accessor :job_queue,
                  :http_open_timeout,
                  :http_read_timeout,
                  :default_max_attempts,
                  :success_codes

    def initialize
      @job_queue = :webhooks
      @http_open_timeout = 5
      @http_read_timeout = 30
      @default_max_attempts = 5
      @success_codes = (200..299).to_a
    end
  end
end
