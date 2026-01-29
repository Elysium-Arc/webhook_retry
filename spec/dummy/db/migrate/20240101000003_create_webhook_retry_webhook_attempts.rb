# frozen_string_literal: true

class CreateWebhookRetryWebhookAttempts < ActiveRecord::Migration[6.0]
  def change
    create_table :webhook_retry_webhook_attempts do |t|
      t.references :webhook, null: false, foreign_key: { to_table: :webhook_retry_webhooks }
      t.integer :attempt_number, null: false
      t.integer :response_status
      t.text :response_body
      t.json :response_headers, default: {}
      t.string :error_class
      t.text :error_message
      t.integer :duration_ms
      t.boolean :success, default: false, null: false

      t.timestamps
    end

    add_index :webhook_retry_webhook_attempts, %i[webhook_id attempt_number], unique: true, name: "idx_webhook_attempts_on_webhook_and_number"
    add_index :webhook_retry_webhook_attempts, :success
  end
end
