# frozen_string_literal: true

require "rails_helper"
require "generators/webhook_retry/install/install_generator"
require "fileutils"

RSpec.describe WebhookRetry::Generators::InstallGenerator do
  let(:destination_root) { File.expand_path("../../../tmp/generator_test", __dir__) }

  before do
    FileUtils.rm_rf(destination_root)
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, "config/initializers"))
    FileUtils.mkdir_p(File.join(destination_root, "db/migrate"))
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  def run_generator
    generator = described_class.new([], { destination_root: destination_root }, { destination_root: destination_root })
    generator.destination_root = destination_root
    capture_output { generator.invoke_all }
  end

  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  describe "install generator" do
    before do
      run_generator
    end

    it "creates the initializer file" do
      expect(File).to exist(File.join(destination_root, "config/initializers/webhook_retry.rb"))
    end

    it "initializer contains configuration block" do
      initializer = File.read(File.join(destination_root, "config/initializers/webhook_retry.rb"))

      expect(initializer).to include("WebhookRetry.configure")
      expect(initializer).to include("config.job_queue")
      expect(initializer).to include("config.http_open_timeout")
      expect(initializer).to include("config.default_max_attempts")
    end

    it "creates webhook_endpoints migration" do
      migration_files = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhook_endpoints.rb")]

      expect(migration_files.length).to eq(1)
    end

    it "creates webhooks migration" do
      migration_files = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhooks.rb")]

      expect(migration_files.length).to eq(1)
    end

    it "creates webhook_attempts migration" do
      migration_files = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhook_attempts.rb")]

      expect(migration_files.length).to eq(1)
    end

    it "migrations have correct order" do
      endpoints = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhook_endpoints.rb")].first
      webhooks = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhooks.rb")].first
      attempts = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhook_attempts.rb")].first

      endpoints_ts = File.basename(endpoints).split("_").first
      webhooks_ts = File.basename(webhooks).split("_").first
      attempts_ts = File.basename(attempts).split("_").first

      expect(endpoints_ts.to_i).to be < webhooks_ts.to_i
      expect(webhooks_ts.to_i).to be < attempts_ts.to_i
    end

    it "webhook_endpoints migration contains correct columns" do
      migration = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhook_endpoints.rb")].first
      content = File.read(migration)

      expect(content).to include("t.string :url")
      expect(content).to include("t.string :host")
      expect(content).to include("t.string :circuit_state")
    end

    it "webhooks migration contains correct columns" do
      migration = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhooks.rb")].first
      content = File.read(migration)

      expect(content).to include("t.references :webhook_endpoint")
      expect(content).to include("t.string :url")
      expect(content).to include("t.jsonb :payload")
      expect(content).to include("t.string :status")
    end

    it "webhook_attempts migration contains correct columns" do
      migration = Dir[File.join(destination_root, "db/migrate/*_create_webhook_retry_webhook_attempts.rb")].first
      content = File.read(migration)

      expect(content).to include("t.references :webhook")
      expect(content).to include("t.integer :attempt_number")
      expect(content).to include("t.integer :response_status")
      expect(content).to include("t.boolean :success")
    end
  end
end
