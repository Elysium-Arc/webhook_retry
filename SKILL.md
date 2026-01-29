# Custom Skills for WebhookRetry

## /test

Run the test suite.

```bash
bundle exec rspec
```

## /test-file

Run tests for a specific file. Usage: `/test-file spec/models/webhook_retry/webhook_spec.rb`

```bash
bundle exec rspec $1
```

## /build

Build the gem package.

```bash
gem build webhook_retry.gemspec
```

## /install-local

Install the gem locally for testing.

```bash
gem build webhook_retry.gemspec && gem install webhook_retry-*.gem
```

## /console

Open an IRB console with the gem loaded.

```bash
cd spec/dummy && bundle exec rails console
```

## /migrate

Run migrations in the dummy app.

```bash
cd spec/dummy && bundle exec rails db:migrate
```

## /generate

Run the install generator in the dummy app.

```bash
cd spec/dummy && bundle exec rails g webhook_retry:install
```

## /lint

Run RuboCop linter.

```bash
bundle exec rubocop
```

## /lint-fix

Run RuboCop with auto-fix.

```bash
bundle exec rubocop -A
```

## /deps

Check gem dependencies.

```bash
bundle check || bundle install
```

## /clean

Remove built gem files.

```bash
rm -f webhook_retry-*.gem
```

## /coverage

Run tests with coverage report.

```bash
COVERAGE=true bundle exec rspec
```

## /dummy-server

Start the dummy Rails app server.

```bash
cd spec/dummy && bundle exec rails server -p 3001
```
