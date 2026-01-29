# CLAUDE.md - Project Context for Claude Code

## Project Overview

**WebhookRetry** is a Rails gem providing robust outgoing webhook infrastructure. Send webhooks to external systems with confidence, knowing that temporary failures are handled automatically, circuit breakers prevent cascading issues, and operations teams have full visibility into delivery status.

## The Problem

Every Rails application that integrates with external services via webhooks faces the same challenges:

- External APIs go down temporarily
- Network issues cause intermittent failures
- No visibility into delivery status
- Manual intervention requires database access
- Lost webhooks mean lost data synchronization
- Each team rebuilds the same infrastructure

## The Solution

WebhookRetry provides battle-tested webhook infrastructure as a Rails gem. Install it once, configure your retry policies, and focus on your business logic instead of reliability concerns.

---

## Current State

**Phase**: Phase 2 - Reliability
**Version**: v0.2.0
**Status**: Complete

### What's Implemented

**Phase 1 - Foundation:**
- Gem skeleton (gemspec, Gemfile, Rakefile)
- Rails Engine with isolated namespace (`WebhookRetry::Engine`)
- Configuration system (`WebhookRetry.configure`)
- Core models: WebhookEndpoint, Webhook, WebhookAttempt
- HTTP Dispatcher service
- ProcessWebhookJob for background delivery
- Public API (`WebhookRetry.enqueue`)
- Install generator with migration templates

**Phase 2 - Reliability:**
- Exponential backoff with jitter (`RetryCalculator`)
- Circuit breaker pattern (`CircuitBreaker`)
- Retry scheduling (`RetryScheduler`)
- Scheduled retry job (`RetryFailedWebhooksJob`)
- Error classification (retryable vs permanent)
- Comprehensive error handling in ProcessWebhookJob
- Full test suite (239 tests passing)

### Files Structure
```
lib/webhook_retry.rb                           # Main entry, public API
lib/webhook_retry/version.rb                   # VERSION
lib/webhook_retry/configuration.rb             # Config DSL (Phase 1 + 2 options)
lib/webhook_retry/engine.rb                    # Rails Engine
lib/webhook_retry/services/
  ├── dispatcher.rb                            # HTTP delivery
  ├── retry_calculator.rb                      # Exponential backoff + jitter
  ├── circuit_breaker.rb                       # Circuit breaker pattern
  ├── retry_scheduler.rb                       # Schedule retries
  └── error_classifier.rb                      # Classify errors
app/models/webhook_retry/*.rb                  # 3 models
app/jobs/webhook_retry/
  ├── process_webhook_job.rb                   # Main delivery job
  └── retry_failed_webhooks_job.rb             # Periodic retry job
lib/generators/webhook_retry/install/          # Install generator
spec/                                          # Test suite (239 tests)
```

---

## Tech Stack

- **Ruby**: 2.7+
- **Rails**: 6.0+ (Rails Engine with isolated namespace)
- **Database**: PostgreSQL (JSONB for payloads/headers)
- **HTTP Client**: Faraday
- **Background Jobs**: ActiveJob (adapter-agnostic)
- **Testing**: RSpec, FactoryBot, WebMock, DatabaseCleaner

---

## Phase 1 Implementation Plan

### Directory Structure
```
webhook_retry/
├── webhook_retry.gemspec
├── Gemfile
├── Rakefile
├── lib/
│   ├── webhook_retry.rb                    # Main entry, public API
│   └── webhook_retry/
│       ├── version.rb                      # VERSION = "0.1.0"
│       ├── configuration.rb                # Config DSL
│       ├── engine.rb                       # Rails Engine
│       ├── errors.rb                       # Custom exceptions
│       └── services/
│           └── dispatcher.rb               # HTTP delivery
├── app/
│   ├── models/webhook_retry/
│   │   ├── webhook.rb
│   │   ├── webhook_attempt.rb
│   │   └── webhook_endpoint.rb
│   └── jobs/webhook_retry/
│       └── process_webhook_job.rb
├── lib/generators/webhook_retry/install/
│   ├── install_generator.rb
│   └── templates/
│       ├── initializer.rb.tt
│       └── migrations/*.rb.tt
└── spec/
    ├── dummy/                              # Test Rails app
    ├── factories/
    └── models/, services/, jobs/
```

### Implementation Order

#### Step 1: Gem Skeleton
1. `webhook_retry.gemspec` - Dependencies: rails >= 6.0, faraday >= 1.0
2. `Gemfile` - Require gemspec
3. `lib/webhook_retry/version.rb` - VERSION = "0.1.0"
4. `Rakefile` - Test tasks

#### Step 2: Rails Engine
1. `lib/webhook_retry/engine.rb`
   - `isolate_namespace WebhookRetry`
   - Configure migration paths
   - Autoload paths
2. `lib/webhook_retry.rb` - Main module with configuration DSL

#### Step 3: Test Infrastructure
1. RSpec setup with dummy Rails app
2. FactoryBot, WebMock, DatabaseCleaner
3. PostgreSQL test database

#### Step 4: Database Migrations (3 tables)

**webhook_retry_webhook_endpoints:**
- `url` (string, unique index)
- `host` (string, index)
- `circuit_state` (default: 'closed')
- `failure_count`, `success_count`

**webhook_retry_webhooks:**
- `webhook_endpoint_id` (FK)
- `url`, `payload` (JSONB), `headers` (JSONB)
- `status` (pending/processing/delivered/failed/dead)
- `attempt_count`, `max_attempts` (default: 5)
- `scheduled_at`, `delivered_at`, `failed_at`
- `idempotency_key`, `metadata` (JSONB)

**webhook_retry_webhook_attempts:**
- `webhook_id` (FK)
- `attempt_number`
- `response_status`, `response_body`, `response_headers`
- `error_class`, `error_message`
- `duration_ms`, `success`

#### Step 5: Models
- **WebhookEndpoint** - URL validation, host extraction
- **Webhook** - Status state machine, `deliverable?`, `mark_delivered!`, `mark_failed!`
- **WebhookAttempt** - Delivery audit trail

#### Step 6: Configuration System
```ruby
WebhookRetry.configure do |config|
  config.job_queue = :webhooks
  config.http_open_timeout = 5
  config.http_read_timeout = 30
  config.default_max_attempts = 5
  config.success_codes = (200..299).to_a
end
```

#### Step 7: Dispatcher Service
- Faraday HTTP client with configurable timeouts
- Returns Result struct: `success?`, `status`, `body`, `headers`, `duration_ms`, `error`
- Handles timeouts, connection errors gracefully

#### Step 8: ProcessWebhookJob
- ActiveJob-based (adapter-agnostic)
- Calls Dispatcher, records attempt
- Marks webhook as delivered or failed

#### Step 9: Public API
```ruby
WebhookRetry.enqueue(
  url: "https://api.example.com/webhook",
  payload: { event: "order.created", data: { id: 123 } },
  headers: { "X-Custom" => "value" },  # optional
  max_attempts: 5,                      # optional
  scheduled_at: 1.hour.from_now         # optional
)
```

#### Step 10: Install Generator
```bash
rails g webhook_retry:install
# Creates:
#   config/initializers/webhook_retry.rb
#   db/migrate/*_create_webhook_retry_*.rb
```

### Files to Create

1. `webhook_retry.gemspec`
2. `Gemfile`
3. `Rakefile`
4. `lib/webhook_retry.rb`
5. `lib/webhook_retry/version.rb`
6. `lib/webhook_retry/engine.rb`
7. `lib/webhook_retry/configuration.rb`
8. `lib/webhook_retry/errors.rb`
9. `lib/webhook_retry/services/dispatcher.rb`
10. `app/models/webhook_retry/webhook.rb`
11. `app/models/webhook_retry/webhook_attempt.rb`
12. `app/models/webhook_retry/webhook_endpoint.rb`
13. `app/jobs/webhook_retry/process_webhook_job.rb`
14. `lib/generators/webhook_retry/install/install_generator.rb`
15. `lib/generators/webhook_retry/install/templates/initializer.rb.tt`
16. `lib/generators/webhook_retry/install/templates/migrations/*.rb.tt` (3 files)
17. `spec/` directory with dummy app and tests

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Rails Engine with `isolate_namespace` | Prevents conflicts; tables prefixed `webhook_retry_` |
| ActiveJob (not Sidekiq directly) | Works with any job backend |
| PostgreSQL JSONB | Native JSON querying, flexible schema |
| Service objects returning Result structs | Testable, no exception-driven control flow |
| Status state machine in model | Clear webhook lifecycle |

---

## Database Tables

All tables are prefixed with `webhook_retry_`:
- `webhook_retry_webhook_endpoints` - Circuit breaker state per destination
- `webhook_retry_webhooks` - Core webhook records
- `webhook_retry_webhook_attempts` - Audit trail of delivery attempts

---

## Webhook Statuses

- `pending` - Awaiting first delivery attempt
- `processing` - Currently being delivered
- `delivered` - Successfully delivered (2xx response)
- `failed` - Exhausted all retry attempts
- `dead` - Permanently failed (dead letter queue)

---

## Common Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/webhook_retry/webhook_spec.rb

# Build the gem
gem build webhook_retry.gemspec

# Install locally
gem install webhook_retry-*.gem

# In a Rails app, run the install generator
rails g webhook_retry:install
rails db:migrate
```

---

## Public API

```ruby
# Enqueue a webhook for delivery
WebhookRetry.enqueue(
  url: "https://api.example.com/webhook",
  payload: { event: "order.created", data: { id: 123 } },
  headers: { "X-Custom" => "value" },  # optional
  max_attempts: 5,                      # optional
  scheduled_at: 1.hour.from_now         # optional
)

# Configuration
WebhookRetry.configure do |config|
  config.job_queue = :webhooks
  config.http_open_timeout = 5
  config.http_read_timeout = 30
  config.default_max_attempts = 5
  config.success_codes = (200..299).to_a
end
```

---

## Testing Approach

- Unit tests for all models, services, and jobs
- Integration tests using a dummy Rails app in `spec/dummy/`
- WebMock for stubbing HTTP requests
- FactoryBot for test data
- DatabaseCleaner for test isolation

---

## Important Files

- `lib/webhook_retry.rb` - Main module and public API
- `lib/webhook_retry/configuration.rb` - All configuration options
- `lib/webhook_retry/services/dispatcher.rb` - HTTP delivery logic
- `app/models/webhook_retry/webhook.rb` - Core webhook model
- `app/jobs/webhook_retry/process_webhook_job.rb` - Delivery job

---

## Code Style

- Follow standard Ruby style
- Use `frozen_string_literal` pragma in all Ruby files
- Service objects return Result structs, not raise exceptions
- Models use ActiveRecord callbacks sparingly
- Prefer explicit over implicit

---

## Verification Plan

1. **Unit tests**: Run `bundle exec rspec` - all specs pass
2. **Generator test**: In dummy app, run `rails g webhook_retry:install` and verify files created
3. **Migration test**: Run `rails db:migrate` successfully
4. **Integration test**:
   ```ruby
   webhook = WebhookRetry.enqueue(url: "https://httpbin.org/post", payload: { test: true })
   # Verify webhook created, job enqueued, delivery succeeds
   ```
5. **Gem build**: `gem build webhook_retry.gemspec` succeeds

---

## Use Cases

### SaaS Platform Integrations
Your application lets users connect external services like Slack, Discord, or custom webhooks. When events occur in your system, reliably notify all connected integrations even if some are temporarily unavailable.

### E-commerce Order Processing
Send order data to fulfillment centers, shipping providers, and inventory systems. Automatic retries ensure orders aren't lost when provider APIs experience downtime.

### API Product with Webhooks
Your API sends webhooks to customer servers. Provide customers with reliability guarantees and operational visibility into delivery status.

### Microservices Communication
Services notify each other asynchronously with guaranteed delivery. Circuit breakers prevent one failing service from degrading the entire system.

### Financial Transaction Notifications
Send payment confirmations, invoice updates, and transaction alerts to accounting systems with complete audit trails for compliance.

---

## How It Works

### Simple Enqueue
```ruby
WebhookRetry.enqueue(
  url: 'https://api.partner.com/webhooks',
  payload: { event: 'user.created', user_id: 123 }
)
```

The gem handles everything else: background job scheduling, HTTP delivery, retry logic, circuit breaker management, and audit logging.

### Retry Strategy (Phase 2)
Failed webhooks are automatically retried with exponential backoff:
- Attempt 1: Immediate delivery
- Attempt 2: 1 minute later
- Attempt 3: 2 minutes later
- Attempt 4: 4 minutes later
- Attempt 5: 8 minutes later

### Circuit Breaker Protection (Phase 2)
When an endpoint fails repeatedly, the circuit breaker opens to prevent wasted resources. After a timeout period, the system attempts limited test requests to check if the endpoint has recovered.

### Admin UI (Phase 3-4)
Operations teams can view webhook status, manually retry failed deliveries, and monitor endpoint health without requiring engineer intervention or database access.

---

## Architecture Overview

### Core Components
- **Models**: Webhook, WebhookAttempt, WebhookEndpoint
- **Services**: Dispatcher (Phase 1), RetryScheduler, CircuitBreaker (Phase 2)
- **Jobs**: ProcessWebhookJob (Phase 1), RetryFailedWebhooksJob (Phase 2)
- **Admin UI**: Dashboard, webhook management, endpoint monitoring (Phase 3-4)

### Integration Points
- Background job adapter (Sidekiq, Good Job, Delayed Job)
- HTTP client (Faraday with configurable middleware)
- Instrumentation (ActiveSupport::Notifications)
- Authentication (your application's auth system)

---

## Roadmap

### v0.1.0 - Foundation (Current)
- Gem skeleton and gemspec configuration
- Database migrations for core tables
- Core models: Webhook, WebhookAttempt, WebhookEndpoint
- Configuration class implementation
- Basic dispatcher service with Faraday
- ProcessWebhookJob for background delivery
- Public enqueue API
- Basic integration tests

### v0.2.0 - Reliability
- Exponential backoff algorithm with jitter
- RetryScheduler service
- RetryFailedWebhooksJob for scheduled retries
- CircuitBreaker service implementation
- Endpoint state tracking and management

### v0.3.0 - Admin UI Core
- Rails Engine routes and authentication
- WebhooksController with index and show
- Basic views with pagination
- Manual retry functionality
- EndpointsController with circuit breaker status

### v0.4.0 - Admin UI Advanced
- Dashboard with statistics and charts
- Bulk retry and delete operations
- CSV export functionality
- Advanced filtering and search
- Real-time updates with Turbo

### v0.5.0 - Instrumentation
- ActiveSupport::Notifications events
- Structured logging
- Metrics collection hooks
- Test helpers for consuming apps

### v1.0.0 - Production Release
- Complete documentation
- Example Rails application
- Security audit
- RubyGems.org release

### Future (Post 1.0)
- v1.1.0: HMAC signatures
- v1.2.0: Idempotency keys, payload templating
- v1.3.0: Rate limiting, multi-tenancy
- v2.0.0: GraphQL API, enterprise features

---

## Out of Scope for Phase 1

These features are planned for later phases:
- Exponential backoff with jitter (Phase 2)
- Circuit breaker logic (Phase 2)
- Admin UI dashboard (Phase 3-4)
- HMAC signatures (v1.1)
- Rate limiting, multi-tenancy (v1.3)

---

## Requirements

- Ruby 2.7 or higher
- Rails 6.0 or higher
- PostgreSQL database (JSONB support required)
- Background job processor (Sidekiq recommended)

---

## Links

- Repository: https://github.com/elysium-arc/webhook_retry
- Documentation: https://github.com/elysium-arc/webhook_retry/wiki
- Issues: https://github.com/elysium-arc/webhook_retry/issues
