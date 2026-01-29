# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookRetry::RetryCalculator do
  describe "#next_retry_delay" do
    subject(:calculator) { described_class.new }

    it "returns base delay for first retry" do
      delay = calculator.next_retry_delay(attempt: 1)

      expect(delay).to be_between(60, 90).inclusive # 60s base + up to 50% jitter
    end

    it "doubles delay for each subsequent attempt" do
      # attempt 1: ~60s, attempt 2: ~120s, attempt 3: ~240s
      delay1 = calculator.next_retry_delay(attempt: 1)
      delay2 = calculator.next_retry_delay(attempt: 2)
      delay3 = calculator.next_retry_delay(attempt: 3)

      # Allow for jitter variance, but base should double
      expect(delay2).to be > delay1
      expect(delay3).to be > delay2
    end

    it "caps delay at max_delay" do
      delay = calculator.next_retry_delay(attempt: 20) # Would be huge without cap

      expect(delay).to be <= WebhookRetry.configuration.max_retry_delay * 1.5 # max + jitter
    end

    it "includes jitter to prevent thundering herd" do
      delays = 10.times.map { calculator.next_retry_delay(attempt: 1) }

      # With jitter, delays should vary
      expect(delays.uniq.size).to be > 1
    end

    it "returns integer seconds" do
      delay = calculator.next_retry_delay(attempt: 1)

      expect(delay).to be_a(Integer)
    end
  end

  describe "#next_retry_at" do
    subject(:calculator) { described_class.new }

    it "returns a Time object" do
      result = calculator.next_retry_at(attempt: 1)

      expect(result).to be_a(Time)
    end

    it "returns a time in the future" do
      freeze_time do
        result = calculator.next_retry_at(attempt: 1)

        expect(result).to be > Time.current
      end
    end

    it "uses the calculated delay" do
      freeze_time do
        allow(calculator).to receive(:next_retry_delay).with(attempt: 2).and_return(120)

        result = calculator.next_retry_at(attempt: 2)

        expect(result).to eq(120.seconds.from_now)
      end
    end
  end

  describe "with custom configuration" do
    before do
      WebhookRetry.configure do |config|
        config.retry_base_delay = 30
        config.max_retry_delay = 300
        config.retry_jitter_factor = 0.25
      end
    end

    after do
      WebhookRetry.reset_configuration!
    end

    it "uses configured base delay" do
      calculator = described_class.new
      delay = calculator.next_retry_delay(attempt: 1)

      # 30s base + up to 25% jitter = 30-37.5
      expect(delay).to be_between(30, 38).inclusive
    end

    it "uses configured max delay" do
      calculator = described_class.new
      delay = calculator.next_retry_delay(attempt: 20)

      # max 300 + up to 25% jitter = max 375
      expect(delay).to be <= 375
    end
  end

  describe "delay progression" do
    subject(:calculator) { described_class.new }

    before do
      WebhookRetry.configure do |config|
        config.retry_base_delay = 60
        config.retry_jitter_factor = 0 # No jitter for predictable testing
      end
    end

    after do
      WebhookRetry.reset_configuration!
    end

    it "follows exponential pattern without jitter" do
      expect(calculator.next_retry_delay(attempt: 1)).to eq(60)   # 60 * 2^0
      expect(calculator.next_retry_delay(attempt: 2)).to eq(120)  # 60 * 2^1
      expect(calculator.next_retry_delay(attempt: 3)).to eq(240)  # 60 * 2^2
      expect(calculator.next_retry_delay(attempt: 4)).to eq(480)  # 60 * 2^3
      expect(calculator.next_retry_delay(attempt: 5)).to eq(960)  # 60 * 2^4
    end
  end
end
