# frozen_string_literal: true

require "faraday"

module WebhookRetry
  class Dispatcher
    Result = Struct.new(:success, :status, :body, :headers, :duration_ms, :error, keyword_init: true) do
      def success?
        success
      end
    end

    def initialize(webhook)
      @webhook = webhook
      @start_time = nil
    end

    def call
      @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = perform_request
      build_success_result(response)
    rescue Faraday::Error => e
      build_error_result(e)
    end

    private

    def perform_request
      connection.post(@webhook.url) do |req|
        req.headers["Content-Type"] = "application/json"
        @webhook.headers.each { |key, value| req.headers[key] = value }
        req.body = @webhook.payload.to_json
      end
    end

    def build_success_result(response)
      Result.new(
        success: success_codes.include?(response.status),
        status: response.status,
        body: response.body,
        headers: response.headers.to_h,
        duration_ms: elapsed_ms,
        error: nil
      )
    end

    def build_error_result(error)
      Result.new(
        success: false,
        status: nil,
        body: nil,
        headers: {},
        duration_ms: elapsed_ms,
        error: error
      )
    end

    def elapsed_ms
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time) * 1000).to_i
    end

    def connection
      @connection ||= Faraday.new do |conn|
        conn.options.open_timeout = WebhookRetry.configuration.http_open_timeout
        conn.options.timeout = WebhookRetry.configuration.http_read_timeout
        conn.adapter Faraday.default_adapter
      end
    end

    def success_codes
      WebhookRetry.configuration.success_codes
    end
  end
end
