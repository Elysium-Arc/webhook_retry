# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_endpoint, class: "WebhookRetry::WebhookEndpoint" do
    sequence(:url) { |n| "https://example.com/webhooks/#{n}" }
    host { URI.parse(url).host }
    circuit_state { "closed" }
    failure_count { 0 }
    success_count { 0 }
  end
end
