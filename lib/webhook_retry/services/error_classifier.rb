# frozen_string_literal: true

module WebhookRetry
  class ErrorClassifier
    RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze
    PERMANENT_FAILURE_RANGE = (400...500).freeze

    def initialize(result)
      @result = result
    end

    def retryable?
      return false if @result.success?
      return true if connection_error?
      return true if RETRYABLE_STATUS_CODES.include?(@result.status)

      false
    end

    def permanent_failure?
      return false if @result.success?
      return false if connection_error?
      return false if @result.status == 429

      PERMANENT_FAILURE_RANGE.include?(@result.status)
    end

    def error_type
      return :success if @result.success?
      return timeout_or_connection_type if connection_error?

      case @result.status
      when 429
        :rate_limited
      when 400...500
        :client_error
      when 500...600
        :server_error
      else
        :unknown
      end
    end

    private

    def connection_error?
      @result.error.present?
    end

    def timeout_or_connection_type
      case @result.error
      when Faraday::TimeoutError
        :timeout
      else
        :connection_error
      end
    end
  end
end
