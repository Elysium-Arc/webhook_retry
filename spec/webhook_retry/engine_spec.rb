# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::Engine do
  it "is a Rails Engine" do
    expect(described_class).to be < Rails::Engine
  end

  it "isolates the namespace" do
    expect(described_class.isolated?).to be true
  end

  it "has the correct engine name" do
    expect(described_class.engine_name).to eq("webhook_retry")
  end
end
