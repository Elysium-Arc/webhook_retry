# frozen_string_literal: true

require_relative "lib/webhook_retry/version"

Gem::Specification.new do |spec|
  spec.name = "webhook_retry"
  spec.version = WebhookRetry::VERSION
  spec.authors = ["Mounir Gaiby"]
  spec.email = ["mounir@example.com"]

  spec.summary = "Robust outgoing webhook infrastructure for Rails"
  spec.description = "A Rails gem that provides automatic retry with exponential backoff, " \
                     "circuit breakers, and operational visibility for outgoing webhooks."
  spec.homepage = "https://github.com/elysium-arc/webhook_retry"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", ">= 1.0"
  spec.add_dependency "rails", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.0"
  spec.add_development_dependency "puma", "~> 6.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "rubocop-rails", "~> 2.0"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
  spec.add_development_dependency "shoulda-matchers", "~> 6.0"
  spec.add_development_dependency "sqlite3", ">= 2.1"
  spec.add_development_dependency "webmock", "~> 3.0"
end
