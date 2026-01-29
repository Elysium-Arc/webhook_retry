# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::CircuitBreaker do
  let(:endpoint) { create(:webhook_endpoint) }

  describe "#allow_request?" do
    context "when circuit is closed" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "closed") }

      it "allows requests" do
        circuit_breaker = described_class.new(endpoint)

        expect(circuit_breaker.allow_request?).to be true
      end
    end

    context "when circuit is open" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "open", circuit_opened_at: 1.minute.ago) }

      it "denies requests" do
        circuit_breaker = described_class.new(endpoint)

        expect(circuit_breaker.allow_request?).to be false
      end

      context "when timeout has passed" do
        let(:endpoint) { create(:webhook_endpoint, circuit_state: "open", circuit_opened_at: 10.minutes.ago) }

        it "transitions to half_open and allows request" do
          circuit_breaker = described_class.new(endpoint)

          expect(circuit_breaker.allow_request?).to be true
          expect(endpoint.reload.circuit_state).to eq("half_open")
        end
      end
    end

    context "when circuit is half_open" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "half_open") }

      it "allows requests (test request)" do
        circuit_breaker = described_class.new(endpoint)

        expect(circuit_breaker.allow_request?).to be true
      end
    end

    context "when circuit breaker is disabled" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "open") }

      before do
        WebhookRetry.configure do |config|
          config.circuit_breaker_enabled = false
        end
      end

      after do
        WebhookRetry.reset_configuration!
      end

      it "always allows requests" do
        circuit_breaker = described_class.new(endpoint)

        expect(circuit_breaker.allow_request?).to be true
      end
    end
  end

  describe "#record_success" do
    context "when circuit is half_open" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "half_open", failure_count: 5) }

      it "closes the circuit" do
        circuit_breaker = described_class.new(endpoint)

        circuit_breaker.record_success

        expect(endpoint.reload.circuit_state).to eq("closed")
      end

      it "resets failure count" do
        circuit_breaker = described_class.new(endpoint)

        circuit_breaker.record_success

        expect(endpoint.reload.failure_count).to eq(0)
      end
    end

    context "when circuit is closed" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "closed") }

      it "keeps circuit closed" do
        circuit_breaker = described_class.new(endpoint)

        circuit_breaker.record_success

        expect(endpoint.reload.circuit_state).to eq("closed")
      end

      it "increments success count" do
        circuit_breaker = described_class.new(endpoint)

        expect { circuit_breaker.record_success }
          .to change { endpoint.reload.success_count }.by(1)
      end
    end
  end

  describe "#record_failure" do
    context "when circuit is closed" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "closed", failure_count: 0) }

      it "increments failure count" do
        circuit_breaker = described_class.new(endpoint)

        expect { circuit_breaker.record_failure }
          .to change { endpoint.reload.failure_count }.by(1)
      end

      it "keeps circuit closed below threshold" do
        circuit_breaker = described_class.new(endpoint)

        circuit_breaker.record_failure

        expect(endpoint.reload.circuit_state).to eq("closed")
      end

      context "when threshold is reached" do
        let(:endpoint) { create(:webhook_endpoint, circuit_state: "closed", failure_count: 4) }

        it "opens the circuit" do
          circuit_breaker = described_class.new(endpoint)

          circuit_breaker.record_failure

          expect(endpoint.reload.circuit_state).to eq("open")
        end

        it "sets circuit_opened_at" do
          circuit_breaker = described_class.new(endpoint)

          freeze_time do
            circuit_breaker.record_failure

            expect(endpoint.reload.circuit_opened_at).to eq(Time.current)
          end
        end
      end
    end

    context "when circuit is half_open" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "half_open") }

      it "opens the circuit again" do
        circuit_breaker = described_class.new(endpoint)

        circuit_breaker.record_failure

        expect(endpoint.reload.circuit_state).to eq("open")
      end
    end

    context "when circuit is open" do
      let(:endpoint) { create(:webhook_endpoint, circuit_state: "open") }

      it "keeps circuit open" do
        circuit_breaker = described_class.new(endpoint)

        circuit_breaker.record_failure

        expect(endpoint.reload.circuit_state).to eq("open")
      end
    end
  end

  describe "#open?" do
    it "returns true when circuit is open" do
      endpoint = create(:webhook_endpoint, circuit_state: "open", circuit_opened_at: 1.minute.ago)
      circuit_breaker = described_class.new(endpoint)

      expect(circuit_breaker.open?).to be true
    end

    it "returns false when circuit is closed" do
      endpoint = create(:webhook_endpoint, circuit_state: "closed")
      circuit_breaker = described_class.new(endpoint)

      expect(circuit_breaker.open?).to be false
    end

    it "returns false when circuit is half_open" do
      endpoint = create(:webhook_endpoint, circuit_state: "half_open")
      circuit_breaker = described_class.new(endpoint)

      expect(circuit_breaker.open?).to be false
    end
  end

  describe "with custom configuration" do
    before do
      WebhookRetry.configure do |config|
        config.circuit_breaker_threshold = 3
        config.circuit_breaker_timeout = 60
      end
    end

    after do
      WebhookRetry.reset_configuration!
    end

    it "uses configured threshold" do
      endpoint = create(:webhook_endpoint, circuit_state: "closed", failure_count: 2)
      circuit_breaker = described_class.new(endpoint)

      circuit_breaker.record_failure

      expect(endpoint.reload.circuit_state).to eq("open")
    end

    it "uses configured timeout" do
      endpoint = create(:webhook_endpoint, circuit_state: "open", circuit_opened_at: 2.minutes.ago)
      circuit_breaker = described_class.new(endpoint)

      expect(circuit_breaker.allow_request?).to be true
      expect(endpoint.reload.circuit_state).to eq("half_open")
    end
  end
end
