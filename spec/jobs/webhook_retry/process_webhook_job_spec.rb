# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::ProcessWebhookJob, type: :job do
  include ActiveJob::TestHelper

  let(:webhook) { create(:webhook, url: "https://example.com/webhook", payload: { event: "test" }) }

  describe "#perform" do
    context "when delivery succeeds" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 200, body: '{"ok": true}', headers: { "Content-Type" => "application/json" })
      end

      it "marks webhook as delivered" do
        described_class.perform_now(webhook.id)

        expect(webhook.reload.status).to eq("delivered")
      end

      it "records the attempt" do
        expect { described_class.perform_now(webhook.id) }
          .to change { webhook.webhook_attempts.count }.by(1)
      end

      it "records successful attempt details" do
        described_class.perform_now(webhook.id)

        attempt = webhook.webhook_attempts.last
        expect(attempt.success).to be true
        expect(attempt.response_status).to eq(200)
        expect(attempt.response_body).to eq('{"ok": true}')
      end

      it "increments attempt count" do
        described_class.perform_now(webhook.id)

        expect(webhook.reload.attempt_count).to eq(1)
      end

      it "records success on endpoint" do
        expect { described_class.perform_now(webhook.id) }
          .to change { webhook.webhook_endpoint.reload.success_count }.by(1)
      end
    end

    context "when delivery fails with server error" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "marks webhook as failed" do
        described_class.perform_now(webhook.id)

        expect(webhook.reload.status).to eq("failed")
      end

      it "records the failed attempt" do
        described_class.perform_now(webhook.id)

        attempt = webhook.webhook_attempts.last
        expect(attempt.success).to be false
        expect(attempt.response_status).to eq(500)
      end

      it "records failure on endpoint" do
        expect { described_class.perform_now(webhook.id) }
          .to change { webhook.webhook_endpoint.reload.failure_count }.by(1)
      end
    end

    context "when delivery times out" do
      before do
        stub_request(:post, "https://example.com/webhook")
          .to_timeout
      end

      it "marks webhook as failed" do
        described_class.perform_now(webhook.id)

        expect(webhook.reload.status).to eq("failed")
      end

      it "records error details in attempt" do
        described_class.perform_now(webhook.id)

        attempt = webhook.webhook_attempts.last
        expect(attempt.success).to be false
        expect(attempt.error_class).to be_present
        expect(attempt.error_message).to be_present
      end
    end

    context "when webhook has reached max attempts" do
      let(:webhook) { create(:webhook, url: "https://example.com/webhook", attempt_count: 4, max_attempts: 5) }

      before do
        stub_request(:post, "https://example.com/webhook")
          .to_return(status: 500)
      end

      it "marks webhook as dead" do
        described_class.perform_now(webhook.id)

        expect(webhook.reload.status).to eq("dead")
      end
    end

    context "when webhook is not deliverable" do
      let(:webhook) { create(:webhook, :delivered) }

      it "does not attempt delivery" do
        expect(WebhookRetry::Dispatcher).not_to receive(:new)

        described_class.perform_now(webhook.id)
      end
    end

    context "when webhook does not exist" do
      it "does not raise error" do
        expect { described_class.perform_now(-1) }.not_to raise_error
      end
    end
  end

  describe "job configuration" do
    it "uses configured queue" do
      job = described_class.new
      expect(job.queue_name).to eq("webhooks")
    end
  end

  describe "enqueueing" do
    it "can be enqueued with webhook id" do
      expect { described_class.perform_later(webhook.id) }
        .to have_enqueued_job(described_class).with(webhook.id)
    end
  end
end
