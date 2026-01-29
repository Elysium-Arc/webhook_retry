# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"
require "database_cleaner/active_record"
require "webmock/rspec"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

# FactoryBot is configured via factory_bot_rails to auto-load from spec/factories

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers

  config.before(:suite) do
    if ActiveRecord::Base.connected?
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
    end
  end

  config.around(:each, :database) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

WebMock.disable_net_connect!(allow_localhost: true)
