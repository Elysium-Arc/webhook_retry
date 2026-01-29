# frozen_string_literal: true

require "rails/generators/testing/behavior"
require "rails/generators/testing/setup_and_teardown"
require "fileutils"

RSpec.configure do |config|
  config.include Rails::Generators::Testing::Behavior, type: :generator
  config.include Rails::Generators::Testing::SetupAndTeardown, type: :generator
  config.include FileUtils, type: :generator
end
