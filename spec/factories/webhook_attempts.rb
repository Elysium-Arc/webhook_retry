# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_attempt, class: "WebhookRetry::WebhookAttempt" do
    webhook
    sequence(:attempt_number) { |n| n }
    response_status { 200 }
    response_body { '{"ok": true}' }
    response_headers { { "Content-Type" => "application/json" } }
    duration_ms { 150 }
    success { true }

    trait :failed do
      response_status { 500 }
      response_body { '{"error": "Internal Server Error"}' }
      success { false }
    end

    trait :timeout do
      response_status { nil }
      response_body { nil }
      error_class { "Faraday::TimeoutError" }
      error_message { "Connection timed out" }
      duration_ms { 30_000 }
      success { false }
    end
  end
end
