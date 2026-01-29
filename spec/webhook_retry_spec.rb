# frozen_string_literal: true

require "spec_helper"
require "webhook_retry"

RSpec.describe WebhookRetry do
  describe "VERSION" do
    it "has a version number" do
      expect(WebhookRetry::VERSION).not_to be_nil
    end

    it "follows semantic versioning format" do
      expect(WebhookRetry::VERSION).to match(/\A\d+\.\d+\.\d+/)
    end

    it "is 0.2.0 for Phase 2 release" do
      expect(WebhookRetry::VERSION).to eq("0.2.0")
    end
  end

  describe "Error" do
    it "defines a base error class" do
      expect(WebhookRetry::Error).to be < StandardError
    end
  end
end
