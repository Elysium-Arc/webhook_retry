# frozen_string_literal: true

module WebhookRetry
  class CircuitBreaker
    STATES = %w[closed open half_open].freeze

    def initialize(endpoint)
      @endpoint = endpoint
    end

    def allow_request?
      return true unless config.circuit_breaker_enabled
      return check_timeout_and_transition if @endpoint.circuit_state == "open"

      true
    end

    def record_success
      @endpoint.record_success!

      return unless @endpoint.circuit_state == "half_open"

      close_circuit
    end

    def record_failure
      @endpoint.record_failure!

      case @endpoint.circuit_state
      when "closed"
        open_circuit_if_threshold_reached
      when "half_open"
        open_circuit
      end
    end

    def open?
      return false unless config.circuit_breaker_enabled

      @endpoint.circuit_state == "open" && !timeout_expired?
    end

    private

    def check_timeout_and_transition
      if timeout_expired?
        transition_to_half_open
        true
      else
        false
      end
    end

    def timeout_expired?
      return true if @endpoint.circuit_opened_at.nil?

      @endpoint.circuit_opened_at < config.circuit_breaker_timeout.seconds.ago
    end

    def open_circuit_if_threshold_reached
      return unless @endpoint.failure_count >= config.circuit_breaker_threshold

      open_circuit
    end

    def open_circuit
      @endpoint.update!(
        circuit_state: "open",
        circuit_opened_at: Time.current
      )
    end

    def close_circuit
      @endpoint.update!(
        circuit_state: "closed",
        failure_count: 0,
        circuit_opened_at: nil
      )
    end

    def transition_to_half_open
      @endpoint.update!(circuit_state: "half_open")
    end

    def config
      WebhookRetry.configuration
    end
  end
end
