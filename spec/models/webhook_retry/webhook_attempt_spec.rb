# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::WebhookAttempt, type: :model do
  describe "validations" do
    subject { build(:webhook_attempt) }

    it { is_expected.to validate_presence_of(:attempt_number) }
    it { is_expected.to validate_numericality_of(:attempt_number).is_greater_than(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:webhook) }
  end

  describe "defaults" do
    it "defaults success to false" do
      attempt = described_class.new
      expect(attempt.success).to be false
    end

    it "defaults response_headers to empty hash" do
      attempt = described_class.new
      expect(attempt.response_headers).to eq({})
    end
  end

  describe ".record!" do
    let(:webhook) { create(:webhook) }

    it "creates a successful attempt record" do
      attempt = described_class.record!(
        webhook: webhook,
        attempt_number: 1,
        response_status: 200,
        response_body: '{"ok": true}',
        response_headers: { "Content-Type" => "application/json" },
        duration_ms: 150,
        success: true
      )

      expect(attempt).to be_persisted
      expect(attempt.response_status).to eq(200)
      expect(attempt.success).to be true
      expect(attempt.duration_ms).to eq(150)
    end

    it "creates a failed attempt record with error info" do
      attempt = described_class.record!(
        webhook: webhook,
        attempt_number: 1,
        error_class: "Faraday::TimeoutError",
        error_message: "Connection timed out",
        duration_ms: 5000,
        success: false
      )

      expect(attempt).to be_persisted
      expect(attempt.error_class).to eq("Faraday::TimeoutError")
      expect(attempt.error_message).to eq("Connection timed out")
      expect(attempt.success).to be false
    end
  end

  describe "scopes" do
    describe ".successful" do
      it "returns only successful attempts" do
        webhook = create(:webhook)
        success = create(:webhook_attempt, webhook: webhook, success: true)
        create(:webhook_attempt, webhook: webhook, success: false)

        expect(described_class.successful).to eq([success])
      end
    end

    describe ".failed" do
      it "returns only failed attempts" do
        webhook = create(:webhook)
        create(:webhook_attempt, webhook: webhook, success: true)
        failure = create(:webhook_attempt, webhook: webhook, success: false)

        expect(described_class.failed).to eq([failure])
      end
    end

    describe ".ordered" do
      it "orders by attempt_number ascending" do
        webhook = create(:webhook)
        third = create(:webhook_attempt, webhook: webhook, attempt_number: 3)
        first = create(:webhook_attempt, webhook: webhook, attempt_number: 1)
        second = create(:webhook_attempt, webhook: webhook, attempt_number: 2)

        expect(described_class.ordered).to eq([first, second, third])
      end
    end
  end
end
