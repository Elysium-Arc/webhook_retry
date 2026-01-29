# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::Dispatcher do
  let(:webhook) { create(:webhook, url: "https://example.com/webhook", payload: { event: "test" }, headers: { "X-Custom" => "value" }) }

  describe "#call" do
    context "when request succeeds with 2xx status" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .with(
            body: { event: "test" }.to_json,
            headers: { "Content-Type" => "application/json", "X-Custom" => "value" }
          )
          .to_return(
            status: 200,
            body: '{"received": true}',
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns a successful result" do
        result = described_class.new(webhook).call

        expect(result).to be_success
      end

      it "includes response status" do
        result = described_class.new(webhook).call

        expect(result.status).to eq(200)
      end

      it "includes response body" do
        result = described_class.new(webhook).call

        expect(result.body).to eq('{"received": true}')
      end

      it "includes response headers" do
        result = described_class.new(webhook).call

        expect(result.headers).to include("content-type" => "application/json")
      end

      it "includes duration in milliseconds" do
        result = described_class.new(webhook).call

        expect(result.duration_ms).to be_a(Integer)
        expect(result.duration_ms).to be >= 0
      end

      it "has no error" do
        result = described_class.new(webhook).call

        expect(result.error).to be_nil
      end
    end

    context "when request fails with 4xx status" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 404, body: "Not Found")
      end

      it "returns a failed result" do
        result = described_class.new(webhook).call

        expect(result).not_to be_success
      end

      it "includes response status" do
        result = described_class.new(webhook).call

        expect(result.status).to eq(404)
      end
    end

    context "when request fails with 5xx status" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "returns a failed result" do
        result = described_class.new(webhook).call

        expect(result).not_to be_success
      end

      it "includes response status" do
        result = described_class.new(webhook).call

        expect(result.status).to eq(500)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_timeout
      end

      it "returns a failed result" do
        result = described_class.new(webhook).call

        expect(result).not_to be_success
      end

      it "has nil status" do
        result = described_class.new(webhook).call

        expect(result.status).to be_nil
      end

      it "includes error" do
        result = described_class.new(webhook).call

        expect(result.error).to be_a(Faraday::Error)
      end
    end

    context "when connection fails" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_raise(Faraday::ConnectionFailed.new("Connection refused"))
      end

      it "returns a failed result" do
        result = described_class.new(webhook).call

        expect(result).not_to be_success
      end

      it "includes error" do
        result = described_class.new(webhook).call

        expect(result.error).to be_a(Faraday::ConnectionFailed)
      end
    end

    context "with custom success codes" do
      before do
        WebhookRetry.configure do |config|
          config.success_codes = [200, 201, 202]
        end

        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 204)
      end

      after do
        WebhookRetry.reset_configuration!
      end

      it "uses configured success codes" do
        result = described_class.new(webhook).call

        expect(result).not_to be_success
      end
    end

    context "with configured timeouts" do
      before do
        WebhookRetry.configure do |config|
          config.http_open_timeout = 10
          config.http_read_timeout = 60
        end
      end

      after do
        WebhookRetry.reset_configuration!
      end

      it "uses configured timeouts" do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200)

        dispatcher = described_class.new(webhook)

        expect(dispatcher.send(:connection).options.open_timeout).to eq(10)
        expect(dispatcher.send(:connection).options.timeout).to eq(60)
      end
    end
  end

  describe "Result struct" do
    it "responds to success?" do
      result = WebhookRetry::Dispatcher::Result.new(
        success: true,
        status: 200,
        body: "",
        headers: {},
        duration_ms: 100,
        error: nil
      )

      expect(result).to respond_to(:success?)
      expect(result.success?).to be true
    end
  end
end
