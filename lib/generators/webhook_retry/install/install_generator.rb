# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

module WebhookRetry
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Creates a WebhookRetry initializer and copies migrations to your application."

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_initializer
        template "initializer.rb.tt", "config/initializers/webhook_retry.rb"
      end

      def copy_migrations
        migration_template(
          "migrations/create_webhook_retry_webhook_endpoints.rb.tt",
          "db/migrate/create_webhook_retry_webhook_endpoints.rb"
        )

        sleep 1 # Ensure unique timestamps

        migration_template(
          "migrations/create_webhook_retry_webhooks.rb.tt",
          "db/migrate/create_webhook_retry_webhooks.rb"
        )

        sleep 1

        migration_template(
          "migrations/create_webhook_retry_webhook_attempts.rb.tt",
          "db/migrate/create_webhook_retry_webhook_attempts.rb"
        )
      end
    end
  end
end
