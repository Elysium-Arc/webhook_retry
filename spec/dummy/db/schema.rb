# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2024_01_01_000003) do
  create_table "webhook_retry_webhook_attempts", force: :cascade do |t|
    t.integer "attempt_number", null: false
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.string "error_class"
    t.text "error_message"
    t.text "response_body"
    t.json "response_headers", default: {}
    t.integer "response_status"
    t.boolean "success", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "webhook_id", null: false
    t.index ["success"], name: "index_webhook_retry_webhook_attempts_on_success"
    t.index ["webhook_id", "attempt_number"], name: "idx_webhook_attempts_on_webhook_and_number", unique: true
    t.index ["webhook_id"], name: "index_webhook_retry_webhook_attempts_on_webhook_id"
  end

  create_table "webhook_retry_webhook_endpoints", force: :cascade do |t|
    t.datetime "circuit_opened_at", precision: nil
    t.string "circuit_state", default: "closed", null: false
    t.datetime "created_at", null: false
    t.integer "failure_count", default: 0, null: false
    t.string "host", null: false
    t.datetime "last_failure_at", precision: nil
    t.datetime "last_success_at", precision: nil
    t.integer "success_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["circuit_state"], name: "index_webhook_retry_webhook_endpoints_on_circuit_state"
    t.index ["host"], name: "index_webhook_retry_webhook_endpoints_on_host"
    t.index ["url"], name: "index_webhook_retry_webhook_endpoints_on_url", unique: true
  end

  create_table "webhook_retry_webhooks", force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.json "headers", default: {}
    t.string "idempotency_key"
    t.integer "max_attempts", default: 5, null: false
    t.json "metadata", default: {}
    t.json "payload", default: {}
    t.datetime "scheduled_at", precision: nil
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.integer "webhook_endpoint_id", null: false
    t.index ["idempotency_key"], name: "index_webhook_retry_webhooks_on_idempotency_key", unique: true
    t.index ["scheduled_at"], name: "index_webhook_retry_webhooks_on_scheduled_at"
    t.index ["status", "scheduled_at"], name: "index_webhook_retry_webhooks_on_status_and_scheduled_at"
    t.index ["status"], name: "index_webhook_retry_webhooks_on_status"
    t.index ["webhook_endpoint_id"], name: "index_webhook_retry_webhooks_on_webhook_endpoint_id"
  end

  add_foreign_key "webhook_retry_webhook_attempts", "webhook_retry_webhooks", column: "webhook_id"
  add_foreign_key "webhook_retry_webhooks", "webhook_retry_webhook_endpoints", column: "webhook_endpoint_id"
end
