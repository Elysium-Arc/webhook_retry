# frozen_string_literal: true

FactoryBot.define do
  factory :webhook, class: "WebhookRetry::Webhook" do
    webhook_endpoint
    sequence(:url) { |n| "https://example.com/webhooks/#{n}" }
    payload { { event: "test.event", data: { id: 1 } } }
    headers { { "Content-Type" => "application/json" } }
    status { "pending" }
    attempt_count { 0 }
    max_attempts { 5 }

    trait :processing do
      status { "processing" }
    end

    trait :delivered do
      status { "delivered" }
      delivered_at { Time.current }
    end

    trait :failed do
      status { "failed" }
      attempt_count { 1 }
      failed_at { Time.current }
    end

    trait :dead do
      status { "dead" }
      attempt_count { 5 }
      failed_at { Time.current }
    end

    trait :scheduled do
      scheduled_at { 1.hour.from_now }
    end
  end
end
