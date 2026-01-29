# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::RetryFailedWebhooksJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "enqueues ProcessWebhookJob for failed webhooks ready for retry" do
      webhook = create(:webhook, :failed, attempt_count: 1, scheduled_at: 1.minute.ago)

      expect { described_class.perform_now }
        .to have_enqueued_job(WebhookRetry::ProcessWebhookJob).with(webhook.id)
    end

    it "does not enqueue for webhooks scheduled in the future" do
      create(:webhook, :failed, attempt_count: 1, scheduled_at: 1.hour.from_now)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(WebhookRetry::ProcessWebhookJob)
    end

    it "does not enqueue for delivered webhooks" do
      create(:webhook, :delivered, scheduled_at: 1.minute.ago)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(WebhookRetry::ProcessWebhookJob)
    end

    it "does not enqueue for dead webhooks" do
      create(:webhook, :dead, scheduled_at: 1.minute.ago)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(WebhookRetry::ProcessWebhookJob)
    end

    it "does not enqueue for webhooks that exhausted attempts" do
      create(:webhook, :failed, attempt_count: 5, max_attempts: 5, scheduled_at: 1.minute.ago)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(WebhookRetry::ProcessWebhookJob)
    end

    it "processes multiple webhooks ready for retry" do
      webhook1 = create(:webhook, :failed, attempt_count: 1, scheduled_at: 2.minutes.ago)
      webhook2 = create(:webhook, :failed, attempt_count: 2, scheduled_at: 1.minute.ago)

      described_class.perform_now

      expect(WebhookRetry::ProcessWebhookJob).to have_been_enqueued.with(webhook1.id)
      expect(WebhookRetry::ProcessWebhookJob).to have_been_enqueued.with(webhook2.id)
    end

    it "clears scheduled_at after enqueueing" do
      webhook = create(:webhook, :failed, attempt_count: 1, scheduled_at: 1.minute.ago)

      described_class.perform_now

      expect(webhook.reload.scheduled_at).to be_nil
    end

    it "skips webhooks with open circuit breaker" do
      endpoint = create(:webhook_endpoint, circuit_state: "open", circuit_opened_at: 1.minute.ago)
      create(:webhook, :failed, webhook_endpoint: endpoint, attempt_count: 1, scheduled_at: 1.minute.ago)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(WebhookRetry::ProcessWebhookJob)
    end

    it "includes webhooks with half_open circuit" do
      endpoint = create(:webhook_endpoint, circuit_state: "half_open")
      webhook = create(:webhook, :failed, webhook_endpoint: endpoint, attempt_count: 1, scheduled_at: 1.minute.ago)

      expect { described_class.perform_now }
        .to have_enqueued_job(WebhookRetry::ProcessWebhookJob).with(webhook.id)
    end

    context "when circuit breaker is disabled" do
      before do
        WebhookRetry.configure do |config|
          config.circuit_breaker_enabled = false
        end
      end

      after do
        WebhookRetry.reset_configuration!
      end

      it "includes webhooks with open circuit" do
        endpoint = create(:webhook_endpoint, circuit_state: "open", circuit_opened_at: 1.minute.ago)
        webhook = create(:webhook, :failed, webhook_endpoint: endpoint, attempt_count: 1, scheduled_at: 1.minute.ago)

        expect { described_class.perform_now }
          .to have_enqueued_job(WebhookRetry::ProcessWebhookJob).with(webhook.id)
      end
    end
  end

  describe "job configuration" do
    it "uses configured queue" do
      job = described_class.new
      expect(job.queue_name).to eq("webhooks")
    end
  end
end
