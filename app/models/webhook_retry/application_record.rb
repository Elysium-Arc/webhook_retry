# frozen_string_literal: true

module WebhookRetry
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.table_name_prefix = "webhook_retry_"
  end
end
