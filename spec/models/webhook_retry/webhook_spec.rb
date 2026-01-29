# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::Webhook, type: :model do
  describe "validations" do
    subject { build(:webhook) }

    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:status) }

    it "validates status inclusion" do
      webhook = build(:webhook, status: "invalid")
      expect(webhook).not_to be_valid
      expect(webhook.errors[:status]).to include("is not included in the list")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:webhook_endpoint) }
    it { is_expected.to have_many(:webhook_attempts).dependent(:destroy) }
  end

  describe "defaults" do
    it "defaults status to pending" do
      webhook = described_class.new
      expect(webhook.status).to eq("pending")
    end

    it "defaults attempt_count to 0" do
      webhook = described_class.new
      expect(webhook.attempt_count).to eq(0)
    end

    it "defaults max_attempts to configured value" do
      webhook = described_class.new
      expect(webhook.max_attempts).to eq(WebhookRetry.configuration.default_max_attempts)
    end
  end

  describe "statuses" do
    it "defines STATUSES constant" do
      expect(described_class::STATUSES).to eq(%w[pending processing delivered failed dead])
    end
  end

  describe "#deliverable?" do
    it "returns true for pending webhooks" do
      webhook = build(:webhook, status: "pending")
      expect(webhook.deliverable?).to be true
    end

    it "returns true for failed webhooks with attempts remaining" do
      webhook = build(:webhook, status: "failed", attempt_count: 2, max_attempts: 5)
      expect(webhook.deliverable?).to be true
    end

    it "returns false for delivered webhooks" do
      webhook = build(:webhook, status: "delivered")
      expect(webhook.deliverable?).to be false
    end

    it "returns false for dead webhooks" do
      webhook = build(:webhook, status: "dead")
      expect(webhook.deliverable?).to be false
    end

    it "returns false when max attempts reached" do
      webhook = build(:webhook, status: "failed", attempt_count: 5, max_attempts: 5)
      expect(webhook.deliverable?).to be false
    end
  end

  describe "#mark_processing!" do
    let(:webhook) { create(:webhook, status: "pending") }

    it "changes status to processing" do
      webhook.mark_processing!
      expect(webhook.reload.status).to eq("processing")
    end
  end

  describe "#mark_delivered!" do
    let(:webhook) { create(:webhook, status: "processing") }

    it "changes status to delivered" do
      webhook.mark_delivered!
      expect(webhook.reload.status).to eq("delivered")
    end

    it "sets delivered_at timestamp" do
      freeze_time do
        webhook.mark_delivered!
        expect(webhook.reload.delivered_at).to eq(Time.current)
      end
    end
  end

  describe "#mark_failed!" do
    context "with attempts remaining" do
      let(:webhook) { create(:webhook, status: "processing", attempt_count: 1, max_attempts: 5) }

      it "changes status to failed" do
        webhook.mark_failed!
        expect(webhook.reload.status).to eq("failed")
      end

      it "sets failed_at timestamp" do
        freeze_time do
          webhook.mark_failed!
          expect(webhook.reload.failed_at).to eq(Time.current)
        end
      end
    end

    context "when max attempts reached" do
      let(:webhook) { create(:webhook, status: "processing", attempt_count: 5, max_attempts: 5) }

      it "changes status to dead" do
        webhook.mark_failed!
        expect(webhook.reload.status).to eq("dead")
      end
    end
  end

  describe "#increment_attempt!" do
    let(:webhook) { create(:webhook, attempt_count: 0) }

    it "increments attempt_count" do
      expect { webhook.increment_attempt! }.to change { webhook.reload.attempt_count }.from(0).to(1)
    end
  end

  describe "scopes" do
    describe ".pending" do
      it "returns only pending webhooks" do
        pending = create(:webhook, status: "pending")
        create(:webhook, status: "delivered")

        expect(described_class.pending).to eq([pending])
      end
    end

    describe ".deliverable" do
      it "returns webhooks that can be delivered" do
        pending = create(:webhook, status: "pending")
        failed_retryable = create(:webhook, status: "failed", attempt_count: 1, max_attempts: 5)
        create(:webhook, status: "delivered")
        create(:webhook, status: "dead")

        expect(described_class.deliverable).to contain_exactly(pending, failed_retryable)
      end
    end

    describe ".scheduled_before" do
      it "returns webhooks scheduled before given time" do
        past = create(:webhook, scheduled_at: 1.hour.ago)
        create(:webhook, scheduled_at: 1.hour.from_now)

        expect(described_class.scheduled_before(Time.current)).to eq([past])
      end

      it "includes webhooks with nil scheduled_at" do
        no_schedule = create(:webhook, scheduled_at: nil)

        expect(described_class.scheduled_before(Time.current)).to include(no_schedule)
      end
    end
  end
end
