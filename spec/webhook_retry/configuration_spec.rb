# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::Configuration do
  subject(:config) { described_class.new }

  describe "default values" do
    it "has default job_queue of :webhooks" do
      expect(config.job_queue).to eq(:webhooks)
    end

    it "has default http_open_timeout of 5 seconds" do
      expect(config.http_open_timeout).to eq(5)
    end

    it "has default http_read_timeout of 30 seconds" do
      expect(config.http_read_timeout).to eq(30)
    end

    it "has default max_attempts of 5" do
      expect(config.default_max_attempts).to eq(5)
    end

    it "has default success_codes of 200-299" do
      expect(config.success_codes).to eq((200..299).to_a)
    end
  end

  describe "setters" do
    it "allows setting job_queue" do
      config.job_queue = :custom_queue
      expect(config.job_queue).to eq(:custom_queue)
    end

    it "allows setting http_open_timeout" do
      config.http_open_timeout = 10
      expect(config.http_open_timeout).to eq(10)
    end

    it "allows setting http_read_timeout" do
      config.http_read_timeout = 60
      expect(config.http_read_timeout).to eq(60)
    end

    it "allows setting default_max_attempts" do
      config.default_max_attempts = 10
      expect(config.default_max_attempts).to eq(10)
    end

    it "allows setting success_codes" do
      config.success_codes = [200, 201, 202]
      expect(config.success_codes).to eq([200, 201, 202])
    end
  end
end

RSpec.describe WebhookRetry do
  describe ".configure" do
    after do
      # Reset configuration after each test
      described_class.instance_variable_set(:@configuration, nil)
    end

    it "yields configuration to a block" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(WebhookRetry::Configuration)
    end

    it "allows configuring via block" do
      described_class.configure do |config|
        config.job_queue = :my_queue
        config.http_open_timeout = 15
      end

      expect(described_class.configuration.job_queue).to eq(:my_queue)
      expect(described_class.configuration.http_open_timeout).to eq(15)
    end
  end

  describe ".configuration" do
    after do
      described_class.instance_variable_set(:@configuration, nil)
    end

    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(WebhookRetry::Configuration)
    end

    it "memoizes the configuration" do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".reset_configuration!" do
    after do
      described_class.instance_variable_set(:@configuration, nil)
    end

    it "resets configuration to defaults" do
      described_class.configure do |config|
        config.job_queue = :custom
      end

      described_class.reset_configuration!

      expect(described_class.configuration.job_queue).to eq(:webhooks)
    end
  end
end
