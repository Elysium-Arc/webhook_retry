# frozen_string_literal: true

class CreateWebhookRetryWebhooks < ActiveRecord::Migration[6.0]
  def change
    create_table :webhook_retry_webhooks do |t|
      t.references :webhook_endpoint, null: false, foreign_key: { to_table: :webhook_retry_webhook_endpoints }
      t.string :url, null: false
      t.json :payload, default: {}
      t.json :headers, default: {}
      t.string :status, default: "pending", null: false
      t.integer :attempt_count, default: 0, null: false
      t.integer :max_attempts, default: 5, null: false
      t.datetime :scheduled_at
      t.datetime :delivered_at
      t.datetime :failed_at
      t.string :idempotency_key
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :webhook_retry_webhooks, :status
    add_index :webhook_retry_webhooks, :scheduled_at
    add_index :webhook_retry_webhooks, :idempotency_key, unique: true
    add_index :webhook_retry_webhooks, %i[status scheduled_at]
  end
end
