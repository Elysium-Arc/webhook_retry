# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::WebhookEndpoint, type: :model do
  describe "validations" do
    subject { build(:webhook_endpoint) }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:host) }
    it { is_expected.to validate_uniqueness_of(:url) }

    it "validates url format" do
      endpoint = build(:webhook_endpoint, url: "not-a-url")
      expect(endpoint).not_to be_valid
      expect(endpoint.errors[:url]).to include("is not a valid URL")
    end

    it "accepts valid https urls" do
      endpoint = build(:webhook_endpoint, url: "https://example.com/webhook")
      expect(endpoint).to be_valid
    end

    it "accepts valid http urls" do
      endpoint = build(:webhook_endpoint, url: "http://example.com/webhook")
      expect(endpoint).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:webhooks).dependent(:destroy) }
  end

  describe "defaults" do
    it "defaults circuit_state to closed" do
      endpoint = described_class.new
      expect(endpoint.circuit_state).to eq("closed")
    end

    it "defaults failure_count to 0" do
      endpoint = described_class.new
      expect(endpoint.failure_count).to eq(0)
    end

    it "defaults success_count to 0" do
      endpoint = described_class.new
      expect(endpoint.success_count).to eq(0)
    end
  end

  describe ".find_or_create_for_url" do
    it "creates a new endpoint for a new url" do
      expect do
        described_class.find_or_create_for_url("https://example.com/webhook")
      end.to change(described_class, :count).by(1)
    end

    it "returns existing endpoint for known url" do
      existing = create(:webhook_endpoint, url: "https://example.com/webhook")

      result = described_class.find_or_create_for_url("https://example.com/webhook")

      expect(result).to eq(existing)
    end

    it "extracts host from url" do
      endpoint = described_class.find_or_create_for_url("https://api.example.com/webhooks/v1")

      expect(endpoint.host).to eq("api.example.com")
    end
  end

  describe "#circuit_open?" do
    it "returns false when circuit is closed" do
      endpoint = build(:webhook_endpoint, circuit_state: "closed")
      expect(endpoint.circuit_open?).to be false
    end

    it "returns true when circuit is open" do
      endpoint = build(:webhook_endpoint, circuit_state: "open")
      expect(endpoint.circuit_open?).to be true
    end

    it "returns false when circuit is half_open" do
      endpoint = build(:webhook_endpoint, circuit_state: "half_open")
      expect(endpoint.circuit_open?).to be false
    end
  end

  describe "#record_success!" do
    let(:endpoint) { create(:webhook_endpoint) }

    it "increments success_count" do
      expect { endpoint.record_success! }.to change { endpoint.reload.success_count }.by(1)
    end

    it "updates last_success_at" do
      freeze_time do
        endpoint.record_success!
        expect(endpoint.reload.last_success_at).to eq(Time.current)
      end
    end
  end

  describe "#record_failure!" do
    let(:endpoint) { create(:webhook_endpoint) }

    it "increments failure_count" do
      expect { endpoint.record_failure! }.to change { endpoint.reload.failure_count }.by(1)
    end

    it "updates last_failure_at" do
      freeze_time do
        endpoint.record_failure!
        expect(endpoint.reload.last_failure_at).to eq(Time.current)
      end
    end
  end
end
