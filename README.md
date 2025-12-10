# WebhookRetry

A production-ready Rails gem that provides robust outgoing webhook infrastructure. Send webhooks to external systems with confidence, knowing that temporary failures are handled automatically, circuit breakers prevent cascading issues, and operations teams have full visibility into delivery status.

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

## What You Get

### Reliability Features
- Automatic retry with exponential backoff
- Jittered delays to prevent thundering herd
- Circuit breaker pattern per endpoint
- Configurable retry policies
- Dead letter queue for permanent failures
- Complete audit trail of all attempts

### Operational Features
- Admin dashboard with delivery statistics
- Search and filter webhooks by status, endpoint, date
- Manual retry for failed webhooks
- Bulk replay operations
- Circuit breaker monitoring and control
- CSV export for analysis

### Developer Features
- Simple enqueue API
- Test helpers for specs
- ActiveSupport::Notifications instrumentation
- Configurable background job adapter
- Structured logging
- Metrics hooks for monitoring systems

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

## How It Works

### Simple Enqueue
```ruby
# In your Rails application
WebhookRetry.enqueue(
  url: 'https://api.partner.com/webhooks',
  payload: { event: 'user.created', user_id: 123 }
)
```

The gem handles everything else: background job scheduling, HTTP delivery, retry logic, circuit breaker management, and audit logging.

### Retry Strategy
Failed webhooks are automatically retried with exponential backoff:
- Attempt 1: Immediate delivery
- Attempt 2: 1 minute later
- Attempt 3: 2 minutes later
- Attempt 4: 4 minutes later
- Attempt 5: 8 minutes later

Configurable delays and retry counts let you tune behavior for your needs.

### Circuit Breaker Protection
When an endpoint fails repeatedly, the circuit breaker opens to prevent wasted resources. After a timeout period, the system attempts limited test requests to check if the endpoint has recovered.

### Admin UI
Operations teams can view webhook status, manually retry failed deliveries, and monitor endpoint health without requiring engineer intervention or database access.

## Architecture Overview

### Core Components
- **Models**: Webhook, WebhookAttempt, WebhookEndpoint
- **Services**: Dispatcher, RetryScheduler, CircuitBreaker, WebhookProcessor
- **Jobs**: ProcessWebhookJob, RetryFailedWebhooksJob
- **Admin UI**: Dashboard, webhook management, endpoint monitoring

### Database Schema
- `webhooks`: Core webhook records with payload and configuration
- `webhook_attempts`: Audit trail of every delivery attempt
- `webhook_endpoints`: Circuit breaker state per destination

### Integration Points
- Background job adapter (Sidekiq, Good Job, Delayed Job)
- HTTP client (Faraday with configurable middleware)
- Instrumentation (ActiveSupport::Notifications)
- Authentication (your application's auth system)

## Planned Features

### Phase 1: Foundation
- Core database models and migrations
- Basic webhook enqueue and delivery
- Simple retry logic
- Background job integration
- Configuration system
- Basic test coverage

### Phase 2: Reliability
- Exponential backoff with jitter
- Circuit breaker implementation
- Retry scheduler service
- Circuit breaker state management
- Scheduled retry job
- Comprehensive error handling

### Phase 3: Admin UI Core
- Rails engine setup
- Webhooks list with pagination
- Webhook detail view with attempt history
- Manual retry functionality
- Endpoint list with circuit breaker status
- Authentication hooks

### Phase 4: Admin UI Advanced
- Dashboard with statistics and charts
- Advanced filtering and search
- Bulk operations
- Date range queries
- CSV export
- Circuit breaker manual controls
- Real-time updates

### Phase 5: Instrumentation
- ActiveSupport::Notifications events
- Structured logging system
- Metrics collection hooks
- Test helpers for consuming apps
- Fake mode for testing
- Performance benchmarks

### Phase 6: Production Ready
- Complete documentation
- Example Rails application
- Migration guides
- API reference
- Troubleshooting guides
- CI/CD pipeline
- Initial gem release

### Future Enhancements
- Idempotency key support
- HMAC webhook signatures
- Payload templating
- Per-endpoint rate limiting
- Multi-tenancy support
- Custom retry schedules
- GraphQL admin API
- Additional job adapters

## Requirements

- Ruby 2.7 or higher
- Rails 6.0 or higher
- PostgreSQL database
- Background job processor

## Project Status

This gem is in active development. Current phase: Foundation.

APIs and features may change before the 1.0 release. Follow the repository for updates.

## Roadmap

**v0.1.0** - Basic delivery and retry  
**v0.2.0** - Circuit breakers and reliability  
**v0.3.0** - Admin UI core  
**v0.4.0** - Admin UI advanced features  
**v0.5.0** - Instrumentation and testing  
**v1.0.0** - Production release with stable API

## Documentation

Documentation is organized into several resources:

### Repository Documentation
- README: Project overview and getting started
- ARCHITECTURE.md: Technical design decisions
- CONTRIBUTING.md: Development guidelines
- CHANGELOG.md: Version history

### Wiki
- Installation Guide
- Configuration Reference
- API Documentation
- Admin UI Guide
- Troubleshooting
- Best Practices

### Issues and Planning
- GitHub Issues: Bug reports and feature requests
- GitHub Projects: Development board
- Linear: Sprint planning and task tracking

## Development Approach

Development follows a structured approach with clear phases. Each phase delivers a working, tested increment. Issues are tracked in GitHub and synced with Linear for sprint planning.

### Development Workflow
1. Phase planning in Linear
2. Feature breakdown into GitHub issues
3. Branch per issue with tests
4. Pull request with review
5. Merge and deploy to test gem
6. Documentation updates

### Testing Strategy
- Unit tests for all services and models
- Integration tests for webhook lifecycle
- Admin UI feature tests
- Test helpers for consuming applications
- Performance and load testing

### Documentation Standards
- All public APIs documented
- Configuration options explained
- Real-world examples provided
- Troubleshooting guides maintained
- Architecture decisions recorded

## Contributing

Contributions are welcome once the initial foundation is established. Guidelines will be provided in CONTRIBUTING.md.

## License

MIT License. See LICENSE file for details.

## Author

[Mounir Gaiby]

## Links

- Repository: https://github.com/elysium-arc/webhook_retry
- Documentation: https://github.com/elysium-arc/webhook_retry/wiki
- Issues: https://github.com/elysium-arc/webhook_retry/issues
- RubyGems: https://rubygems.org/gems/webhook_retry (after release)

---

**Note**: This is a greenfield project in initial development. Watch the repository for updates as features are implemented.
