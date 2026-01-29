# frozen_string_literal: true

module WebhookRetry
  class Webhook < ApplicationRecord
    STATUSES = %w[pending processing delivered failed dead].freeze

    belongs_to :webhook_endpoint
    has_many :webhook_attempts, dependent: :destroy

    validates :url, presence: true
    validates :status, presence: true, inclusion: { in: STATUSES }

    attribute :status, :string, default: "pending"
    attribute :attempt_count, :integer, default: 0
    attribute :max_attempts, :integer, default: -> { WebhookRetry.configuration.default_max_attempts }

    scope :pending, -> { where(status: "pending") }
    scope :deliverable, -> { where(status: %w[pending failed]).where("attempt_count < max_attempts") }
    scope :scheduled_before, ->(time) { where("scheduled_at IS NULL OR scheduled_at <= ?", time) }

    def deliverable?
      return false if %w[delivered dead].include?(status)
      return false if attempt_count >= max_attempts

      true
    end

    def mark_processing!
      update!(status: "processing")
    end

    def mark_delivered!
      update!(
        status: "delivered",
        delivered_at: Time.current
      )
    end

    def mark_failed!
      new_status = attempt_count >= max_attempts ? "dead" : "failed"
      update!(
        status: new_status,
        failed_at: Time.current
      )
    end

    def increment_attempt!
      increment!(:attempt_count)
    end
  end
end
