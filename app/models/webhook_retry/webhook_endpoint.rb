# frozen_string_literal: true

module WebhookRetry
  class WebhookEndpoint < ApplicationRecord
    has_many :webhooks, dependent: :destroy

    validates :url, presence: true, uniqueness: true
    validates :host, presence: true
    validate :url_format

    CIRCUIT_STATES = %w[closed open half_open].freeze

    def self.find_or_create_for_url(url)
      uri = URI.parse(url)
      find_or_create_by!(url: url) do |endpoint|
        endpoint.host = uri.host
      end
    end

    def circuit_open?
      circuit_state == "open"
    end

    def record_success!
      update!(
        success_count: success_count + 1,
        last_success_at: Time.current
      )
    end

    def record_failure!
      update!(
        failure_count: failure_count + 1,
        last_failure_at: Time.current
      )
    end

    private

    def url_format
      uri = URI.parse(url)
      errors.add(:url, "is not a valid URL") unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      errors.add(:url, "is not a valid URL")
    end
  end
end
