# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::ErrorClassifier do
  describe "#retryable?" do
    context "with HTTP status codes" do
      it "returns true for 500 Internal Server Error" do
        result = build_result(status: 500)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be true
      end

      it "returns true for 502 Bad Gateway" do
        result = build_result(status: 502)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be true
      end

      it "returns true for 503 Service Unavailable" do
        result = build_result(status: 503)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be true
      end

      it "returns true for 504 Gateway Timeout" do
        result = build_result(status: 504)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be true
      end

      it "returns true for 429 Too Many Requests" do
        result = build_result(status: 429)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be true
      end

      it "returns false for 400 Bad Request" do
        result = build_result(status: 400)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be false
      end

      it "returns false for 401 Unauthorized" do
        result = build_result(status: 401)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be false
      end

      it "returns false for 403 Forbidden" do
        result = build_result(status: 403)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be false
      end

      it "returns false for 404 Not Found" do
        result = build_result(status: 404)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be false
      end

      it "returns false for 422 Unprocessable Entity" do
        result = build_result(status: 422)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be false
      end
    end

    context "with connection errors" do
      it "returns true for timeout errors" do
        result = build_result(status: nil, error: Faraday::TimeoutError.new)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be true
      end

      it "returns true for connection failed errors" do
        result = build_result(status: nil, error: Faraday::ConnectionFailed.new("refused"))
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be true
      end

      it "returns true for SSL errors" do
        result = build_result(status: nil, error: Faraday::SSLError.new)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be true
      end
    end

    context "with successful responses" do
      it "returns false for 200 OK" do
        result = build_result(status: 200, success: true)
        classifier = described_class.new(result)

        expect(classifier.retryable?).to be false
      end
    end
  end

  describe "#permanent_failure?" do
    it "returns true for 4xx errors (except 429)" do
      result = build_result(status: 404)
      classifier = described_class.new(result)

      expect(classifier.permanent_failure?).to be true
    end

    it "returns false for 429 Too Many Requests" do
      result = build_result(status: 429)
      classifier = described_class.new(result)

      expect(classifier.permanent_failure?).to be false
    end

    it "returns false for 5xx errors" do
      result = build_result(status: 500)
      classifier = described_class.new(result)

      expect(classifier.permanent_failure?).to be false
    end

    it "returns false for connection errors" do
      result = build_result(status: nil, error: Faraday::TimeoutError.new)
      classifier = described_class.new(result)

      expect(classifier.permanent_failure?).to be false
    end

    it "returns false for successful responses" do
      result = build_result(status: 200, success: true)
      classifier = described_class.new(result)

      expect(classifier.permanent_failure?).to be false
    end
  end

  describe "#error_type" do
    it "returns :success for successful responses" do
      result = build_result(status: 200, success: true)
      classifier = described_class.new(result)

      expect(classifier.error_type).to eq(:success)
    end

    it "returns :server_error for 5xx" do
      result = build_result(status: 503)
      classifier = described_class.new(result)

      expect(classifier.error_type).to eq(:server_error)
    end

    it "returns :client_error for 4xx" do
      result = build_result(status: 404)
      classifier = described_class.new(result)

      expect(classifier.error_type).to eq(:client_error)
    end

    it "returns :rate_limited for 429" do
      result = build_result(status: 429)
      classifier = described_class.new(result)

      expect(classifier.error_type).to eq(:rate_limited)
    end

    it "returns :timeout for timeout errors" do
      result = build_result(status: nil, error: Faraday::TimeoutError.new)
      classifier = described_class.new(result)

      expect(classifier.error_type).to eq(:timeout)
    end

    it "returns :connection_error for connection failures" do
      result = build_result(status: nil, error: Faraday::ConnectionFailed.new("refused"))
      classifier = described_class.new(result)

      expect(classifier.error_type).to eq(:connection_error)
    end
  end

  private

  def build_result(status:, success: false, error: nil)
    WebhookRetry::Dispatcher::Result.new(
      success: success,
      status: status,
      body: nil,
      headers: {},
      duration_ms: 100,
      error: error
    )
  end
end
