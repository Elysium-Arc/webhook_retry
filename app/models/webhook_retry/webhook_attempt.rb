# frozen_string_literal: true

module WebhookRetry
  class WebhookAttempt < ApplicationRecord
    belongs_to :webhook

    validates :attempt_number, presence: true, numericality: { greater_than: 0 }

    attribute :success, :boolean, default: false
    attribute :response_headers, :json, default: -> { {} }

    scope :successful, -> { where(success: true) }
    scope :failed, -> { where(success: false) }
    scope :ordered, -> { order(attempt_number: :asc) }

    def self.record!(webhook:, attempt_number:, success:, **attributes)
      create!(
        webhook: webhook,
        attempt_number: attempt_number,
        success: success,
        **attributes
      )
    end
  end
end
