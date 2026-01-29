# frozen_string_literal: true

require "rails_helper"

RSpec.describe "WebhookRetry.enqueue" do
  include ActiveJob::TestHelper

  describe ".enqueue" do
    let(:url) { "https://api.example.com/webhooks" }
    let(:payload) { { event: "order.created", data: { id: 123 } } }

    it "creates a webhook record" do
      expect { WebhookRetry.enqueue(url: url, payload: payload) }
        .to change(WebhookRetry::Webhook, :count).by(1)
    end

    it "returns the created webhook" do
      webhook = WebhookRetry.enqueue(url: url, payload: payload)

      expect(webhook).to be_a(WebhookRetry::Webhook)
      expect(webhook).to be_persisted
    end

    it "stores the url" do
      webhook = WebhookRetry.enqueue(url: url, payload: payload)

      expect(webhook.url).to eq(url)
    end

    it "stores the payload" do
      webhook = WebhookRetry.enqueue(url: url, payload: payload)

      expect(webhook.payload).to eq("event" => "order.created", "data" => { "id" => 123 })
    end

    it "creates or finds the webhook endpoint" do
      expect { WebhookRetry.enqueue(url: url, payload: payload) }
        .to change(WebhookRetry::WebhookEndpoint, :count).by(1)
    end

    it "reuses existing endpoint for same url" do
      WebhookRetry.enqueue(url: url, payload: payload)

      expect { WebhookRetry.enqueue(url: url, payload: { event: "another" }) }
        .not_to change(WebhookRetry::WebhookEndpoint, :count)
    end

    it "enqueues a ProcessWebhookJob" do
      expect { WebhookRetry.enqueue(url: url, payload: payload) }
        .to have_enqueued_job(WebhookRetry::ProcessWebhookJob)
    end

    it "enqueues job with webhook id" do
      webhook = WebhookRetry.enqueue(url: url, payload: payload)

      expect(WebhookRetry::ProcessWebhookJob).to have_been_enqueued.with(webhook.id)
    end

    context "with optional headers" do
      it "stores custom headers" do
        webhook = WebhookRetry.enqueue(
          url: url,
          payload: payload,
          headers: { "X-API-Key" => "secret", "X-Request-ID" => "abc123" }
        )

        expect(webhook.headers).to eq("X-API-Key" => "secret", "X-Request-ID" => "abc123")
      end
    end

    context "with optional max_attempts" do
      it "uses custom max_attempts" do
        webhook = WebhookRetry.enqueue(url: url, payload: payload, max_attempts: 10)

        expect(webhook.max_attempts).to eq(10)
      end

      it "uses default when not specified" do
        webhook = WebhookRetry.enqueue(url: url, payload: payload)

        expect(webhook.max_attempts).to eq(WebhookRetry.configuration.default_max_attempts)
      end
    end

    context "with scheduled_at" do
      it "stores scheduled_at" do
        scheduled = 1.hour.from_now
        webhook = WebhookRetry.enqueue(url: url, payload: payload, scheduled_at: scheduled)

        expect(webhook.scheduled_at).to be_within(1.second).of(scheduled)
      end

      it "schedules job for later" do
        scheduled = 1.hour.from_now

        expect { WebhookRetry.enqueue(url: url, payload: payload, scheduled_at: scheduled) }
          .to have_enqueued_job(WebhookRetry::ProcessWebhookJob).at(scheduled)
      end
    end

    context "with idempotency_key" do
      it "stores idempotency_key" do
        webhook = WebhookRetry.enqueue(url: url, payload: payload, idempotency_key: "unique-123")

        expect(webhook.idempotency_key).to eq("unique-123")
      end

      it "returns existing webhook for duplicate idempotency_key" do
        first = WebhookRetry.enqueue(url: url, payload: payload, idempotency_key: "unique-123")
        second = WebhookRetry.enqueue(url: url, payload: { different: true }, idempotency_key: "unique-123")

        expect(second).to eq(first)
      end

      it "does not create duplicate webhooks" do
        WebhookRetry.enqueue(url: url, payload: payload, idempotency_key: "unique-123")

        expect { WebhookRetry.enqueue(url: url, payload: payload, idempotency_key: "unique-123") }
          .not_to change(WebhookRetry::Webhook, :count)
      end

      it "does not enqueue duplicate jobs" do
        WebhookRetry.enqueue(url: url, payload: payload, idempotency_key: "unique-123")
        clear_enqueued_jobs

        expect { WebhookRetry.enqueue(url: url, payload: payload, idempotency_key: "unique-123") }
          .not_to have_enqueued_job(WebhookRetry::ProcessWebhookJob)
      end
    end

    context "with metadata" do
      it "stores metadata" do
        webhook = WebhookRetry.enqueue(
          url: url,
          payload: payload,
          metadata: { user_id: 42, source: "api" }
        )

        expect(webhook.metadata).to eq("user_id" => 42, "source" => "api")
      end
    end

    context "with invalid url" do
      it "raises an error" do
        expect { WebhookRetry.enqueue(url: "not-a-url", payload: payload) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
