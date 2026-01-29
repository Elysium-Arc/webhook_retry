# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::RetryScheduler do
  describe "#schedule_retry" do
    let(:webhook) { create(:webhook, :failed, attempt_count: 2, max_attempts: 5) }

    it "updates webhook scheduled_at" do
      scheduler = described_class.new(webhook)

      freeze_time do
        scheduler.schedule_retry

        expect(webhook.reload.scheduled_at).to be > Time.current
      end
    end

    it "uses retry calculator for delay" do
      scheduler = described_class.new(webhook)
      calculator = instance_double(WebhookRetry::RetryCalculator)

      allow(WebhookRetry::RetryCalculator).to receive(:new).and_return(calculator)
      allow(calculator).to receive(:next_retry_at).with(attempt: 3).and_return(1.hour.from_now)

      scheduler.schedule_retry

      expect(calculator).to have_received(:next_retry_at).with(attempt: 3)
    end

    it "returns true on success" do
      scheduler = described_class.new(webhook)

      expect(scheduler.schedule_retry).to be true
    end

    context "when webhook is not retryable" do
      let(:webhook) { create(:webhook, :delivered) }

      it "returns false" do
        scheduler = described_class.new(webhook)

        expect(scheduler.schedule_retry).to be false
      end

      it "does not update scheduled_at" do
        scheduler = described_class.new(webhook)

        expect { scheduler.schedule_retry }.not_to(change { webhook.reload.scheduled_at })
      end
    end

    context "when webhook has exhausted attempts" do
      let(:webhook) { create(:webhook, :failed, attempt_count: 5, max_attempts: 5) }

      it "returns false" do
        scheduler = described_class.new(webhook)

        expect(scheduler.schedule_retry).to be false
      end
    end
  end

  describe "#retryable?" do
    it "returns true for failed webhooks with attempts remaining" do
      webhook = create(:webhook, :failed, attempt_count: 2, max_attempts: 5)
      scheduler = described_class.new(webhook)

      expect(scheduler.retryable?).to be true
    end

    it "returns false for delivered webhooks" do
      webhook = create(:webhook, :delivered)
      scheduler = described_class.new(webhook)

      expect(scheduler.retryable?).to be false
    end

    it "returns false for dead webhooks" do
      webhook = create(:webhook, :dead)
      scheduler = described_class.new(webhook)

      expect(scheduler.retryable?).to be false
    end

    it "returns false when max attempts reached" do
      webhook = create(:webhook, :failed, attempt_count: 5, max_attempts: 5)
      scheduler = described_class.new(webhook)

      expect(scheduler.retryable?).to be false
    end

    it "returns false for pending webhooks (not yet tried)" do
      webhook = create(:webhook, status: "pending")
      scheduler = described_class.new(webhook)

      expect(scheduler.retryable?).to be false
    end
  end

  describe ".schedule_all_pending_retries" do
    it "schedules retries for all failed webhooks without scheduled_at" do
      failed1 = create(:webhook, :failed, attempt_count: 1, scheduled_at: nil)
      failed2 = create(:webhook, :failed, attempt_count: 2, scheduled_at: nil)
      _already_scheduled = create(:webhook, :failed, attempt_count: 1, scheduled_at: 1.hour.from_now)
      _delivered = create(:webhook, :delivered)

      count = described_class.schedule_all_pending_retries

      expect(count).to eq(2)
      expect(failed1.reload.scheduled_at).to be_present
      expect(failed2.reload.scheduled_at).to be_present
    end

    it "returns count of scheduled webhooks" do
      create(:webhook, :failed, attempt_count: 1, scheduled_at: nil)
      create(:webhook, :failed, attempt_count: 2, scheduled_at: nil)

      expect(described_class.schedule_all_pending_retries).to eq(2)
    end

    it "returns 0 when no webhooks to schedule" do
      expect(described_class.schedule_all_pending_retries).to eq(0)
    end
  end
end
