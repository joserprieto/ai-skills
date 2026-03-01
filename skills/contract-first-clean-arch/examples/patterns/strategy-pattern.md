# Strategy pattern via ports

Swap between multiple implementations of the same concern using port interfaces
and composition root wiring.

## Problem

Your application needs to support multiple implementations of the same behavior.
A payment gateway that could be Stripe today and Braintree tomorrow. A notification
channel that sends email in production and logs to console in development. An AI
provider that uses one vendor for batch processing and another for real-time.

Without a clean boundary, you end up with if/else chains scattered through
business logic, or use cases that import concrete vendor libraries directly.
Swapping implementations requires changing domain code.

## Pattern

Define a **port interface** in the domain layer that describes the behavior
contract. Provide multiple concrete implementations in infrastructure. Select
the active implementation in the **composition root** based on configuration.

The use case depends only on the port. It never knows which implementation is
active. Swapping providers is a configuration change, not a code change.

```
┌──────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                            │
│                                                               │
│  ┌───────────────┐     ┌──────────────────────────────────┐  │
│  │ PurchaseOrder │────>│  PaymentGateway (port)           │  │
│  │               │     │                                  │  │
│  │               │     │  charge(amount, token) -> Result │  │
│  │               │     │  refund(charge_id) -> Result     │  │
│  └───────────────┘     └───────────────┬──────────────────┘  │
│                                        │ interface            │
└────────────────────────────────────────┼─────────────────────┘
                                         │
    ┌────────────────────────────────────┼─────────────────────────┐
    │            INFRASTRUCTURE          │                         │
    │                                    │ implements              │
    │    ┌───────────────────────────────┼──────────────────────┐  │
    │    │                               │                     │  │
    │    ▼                               ▼                     ▼  │
    │ ┌────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
    │ │ Stripe         │  │ Braintree        │  │ Test         │  │
    │ │ Payment        │  │ Payment          │  │ Payment      │  │
    │ │ Gateway        │  │ Gateway          │  │ Gateway      │  │
    │ │                │  │                  │  │              │  │
    │ │ Stripe SDK     │  │ Braintree SDK    │  │ HashMap      │  │
    │ │ API calls      │  │ API calls        │  │ in-mem       │  │
    │ └────────────────┘  └──────────────────┘  └──────────────┘  │
    │  (production)        (alternative)         (testing)        │
    └─────────────────────────────────────────────────────────────┘
                                         ▲
    ┌────────────────────────────────────┼─────────────────────────┐
    │         COMPOSITION ROOT           │                         │
    │                                    │ selects                 │
    │  config.payment = "stripe"                                   │
    │    → inject StripePaymentGateway into PurchaseOrder           │
    └─────────────────────────────────────────────────────────────┘
```

## When to use

- **Payment gateways**: Stripe, Braintree, Adyen, PayPal
- **Notification channels**: email, SMS, push notification, Slack
- **AI/ML providers**: OpenAI, Anthropic, local models
- **Storage backends**: S3, Azure Blob, local filesystem
- **Search engines**: Elasticsearch, Algolia, database full-text search
- **Authentication**: OAuth providers, LDAP, SAML, local credentials
- Any concern where multiple vendors or implementations are realistic

## Layers involved

| Layer                      | Role                              | Contains                            |
|----------------------------|-----------------------------------|-------------------------------------|
| `domain/ports/`            | Defines the behavior contract     | `PaymentGateway` interface          |
| `infrastructure/external/` | Provides concrete implementations | `StripePaymentGateway`, `BraintreePaymentGateway` |
| `test/doubles/`            | Provides test implementation      | `InMemoryPaymentGateway`            |
| Composition root           | Selects active implementation     | Configuration-based wiring          |

## How it differs from Repository

Both patterns use the port/adapter mechanism, but they serve different purposes:

| Aspect          | Repository                           | Strategy                                      |
|-----------------|--------------------------------------|-----------------------------------------------|
| Concern         | Data persistence (CRUD)              | Behavioral alternatives                       |
| Interface shape | `save`, `find`, `search`             | Domain-specific operations                    |
| Implementations | Storage backends (SQL, file, memory) | Service providers (Stripe, Braintree)         |
| Swapping reason | Testing, migration                   | Vendor change, A/B testing, cost optimization |
| Typical count   | One per aggregate                    | One per external concern                      |

The distinction matters for naming and organization. Repositories live in
`infrastructure/persistence/`. Strategy implementations live in
`infrastructure/external/`.

## Selection mechanisms

The composition root selects the implementation. Common approaches:

- **Environment variable**: `PAYMENT_PROVIDER=stripe` picks `StripePaymentGateway`
- **Configuration file**: Application config maps provider name to implementation
- **Feature flag**: A/B testing between providers at runtime
- **Per-tenant**: Multi-tenant systems where each tenant uses a different provider

The selection logic lives ONLY in the composition root. Use cases never contain
provider selection logic.

## Common mistakes

**If/else chains instead of polymorphism**: A use case that checks
`if provider == "stripe" then ... else if provider == "braintree" then ...`
defeats the purpose. The port interface provides polymorphism for free.

**Strategy selection in the domain layer**: The domain should receive an already-
selected implementation via its constructor. It should never inspect configuration
to choose a provider.

**Not having a test implementation**: Without an in-memory test double, every
test that exercises the use case must mock the payment gateway. A proper test
implementation (that records charges in a list and always succeeds) makes tests
simple and readable.

**Leaking provider-specific types**: If the port interface accepts a `StripeToken`
parameter, it is not a proper abstraction. The interface should use domain types
like `PaymentToken` that any implementation can work with.

**Inconsistent behavior across implementations**: All implementations must honor
the same contract. If `StripePaymentGateway` throws on invalid amounts but
`BraintreePaymentGateway` silently fails, the use case behaves differently depending
on configuration. Define expected behavior in the port documentation.
