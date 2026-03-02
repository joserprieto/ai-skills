# Infrastructure doubling

Create lightweight in-process implementations of ports so that tests run fast, deterministically,
and without external dependencies.

## Problem

Tests that depend on real infrastructure — databases, APIs, message brokers, file systems — are
slow, flaky, and expensive. A test suite that needs a running PostgreSQL, a live Stripe sandbox, and
an SMTP server takes minutes to start, fails when the network is down, and costs money for every CI
run.

Worse, these tests conflate two concerns: "does the business logic work?" and "does the
infrastructure integration work?" When a test fails, you cannot tell whether the bug is in your
domain logic or in the database connection.

## Pattern

Create **lightweight, in-process implementations** of port interfaces that behave like the real
infrastructure but run entirely in memory. Use these implementations for unit and acceptance tests.
Reserve real infrastructure for dedicated integration tests.

Because ports define the boundary, any implementation that satisfies the interface is valid — the
domain does not know (and does not care) whether it is talking to PostgreSQL or a dictionary in
memory.

```
┌──────────────────────────────────────────────────────────────┐
│                    PRODUCTION WIRING                          │
│                                                               │
│  PurchaseOrder ─> OrderRepository port ─> PostgresOrderRepo  │
│               ─> PaymentGateway port  ─> StripePaymentGW    │
│               ─> EventBus port        ─> RabbitMqEventBus   │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    TEST WIRING                                │
│                                                               │
│  PurchaseOrder ─> OrderRepository port ─> InMemoryOrderRepository  │
│               ─> PaymentGateway port  ─> StubPaymentGateway │
│               ─> EventBus port        ─> SpyEventBus        │
│                                                               │
│  All doubles run in-process. No network. No containers.      │
│  Milliseconds, not seconds.                                  │
└──────────────────────────────────────────────────────────────┘
```

## When to use

- Any port that touches external systems: databases, APIs, message brokers, file systems, email
  services, cloud storage
- Unit tests that exercise use case logic
- Acceptance tests that verify full workflows
- Development environments where real infrastructure is not available
- CI pipelines where speed and determinism matter

## Types of test doubles

Each type of double serves a different testing purpose:

### Fake (in-memory implementation)

A fully functional implementation backed by in-memory data structures. It implements the complete
port interface with real behavior — items saved can be retrieved, searches return matching results.

```
┌──────────────────────────────────────────────┐
│          InMemoryOrderRepositorysitory             │
│                                              │
│  Internal: HashMap<OrderId, Order>           │
│                                              │
│  save(order):                                │
│    store order in map                        │
│                                              │
│  find(id):                                   │
│    look up in map, return if found           │
│                                              │
│  search(criteria):                           │
│    filter map values by criteria fields      │
│    (see criteria-pattern.md)                 │
│                                              │
│  Behavior: identical to real repo            │
│  Speed: microseconds                         │
│  Setup: none                                 │
└──────────────────────────────────────────────┘
```

**Use for**: repositories, caches, any port where state and retrieval matter.

### Stub (canned responses)

Returns pre-configured responses without implementing real behavior. Does not maintain state between
calls.

```
┌──────────────────────────────────────────────┐
│          StubPaymentGateway                  │
│                                              │
│  charge(amount, token):                      │
│    return ChargeResult.success("ch_fake_1")  │
│                                              │
│  refund(charge_id):                          │
│    return RefundResult.success()             │
│                                              │
│  Configurable: set next response per test    │
│  Can simulate: success, failure, timeout     │
└──────────────────────────────────────────────┘
```

**Use for**: external services where you control the scenario (payment succeeds, payment fails,
service unavailable).

### Spy (records calls)

Records every method call and its arguments so tests can verify interactions.

```
┌──────────────────────────────────────────────┐
│              SpyEventBus                     │
│                                              │
│  Internal: List<PublishedEvent>              │
│                                              │
│  publish(event):                             │
│    add event to list                         │
│                                              │
│  published_events():                         │
│    return copy of list                       │
│                                              │
│  Test assertion:                             │
│    "OrderCreated event was published"        │
│    "Event contains correct order ID"         │
└──────────────────────────────────────────────┘
```

**Use for**: event buses, notification services, audit loggers — any port where you need to verify
that something was sent.

### Mock (verifies expectations)

A spy that also fails the test if expected interactions do not occur. Most testing frameworks
provide mock libraries. Use sparingly — prefer fakes and spies for readability.

## Layers involved

| Layer             | Role                   | Contains                                                                     |
| ----------------- | ---------------------- | ---------------------------------------------------------------------------- |
| `domain/ports/`   | Defines the interfaces | `OrderRepository`, `PaymentGateway`, `EventBus`                              |
| `infrastructure/` | Real implementations   | `PostgresOrderRepository` (persistence/), `StripePaymentGateway` (external/) |
| `test/doubles/`   | Test implementations   | `InMemoryOrderRepository`, `StubPaymentGateway`, `SpyEventBus`               |

Test doubles implement the SAME port interfaces as production implementations. They live in the test
directory because production code never depends on them.

## Test architecture

```
┌───────────────────────────────────────────────────────────┐
│  UNIT TESTS (fast, isolated, most numerous)               │
│                                                           │
│  Application service + Fakes/Stubs/Spies                   │
│  → Test: business logic, validation, edge cases           │
│  → Speed: milliseconds                                    │
│  → Infra needed: none                                     │
├───────────────────────────────────────────────────────────┤
│  ACCEPTANCE TESTS (fast, full workflow)                    │
│                                                           │
│  Multiple application services + Fakes + Spies             │
│  → Test: end-to-end scenarios with in-memory infra        │
│  → Speed: milliseconds to low seconds                     │
│  → Infra needed: none                                     │
├───────────────────────────────────────────────────────────┤
│  INTEGRATION TESTS (slower, targeted)                     │
│                                                           │
│  Real implementation + real infrastructure                 │
│  → Test: SQL queries work, API client handles responses   │
│  → Speed: seconds                                         │
│  → Infra needed: database, external sandbox               │
├───────────────────────────────────────────────────────────┤
│  E2E TESTS (slowest, fewest)                              │
│                                                           │
│  Full application + real everything                        │
│  → Test: system works when fully assembled                │
│  → Speed: seconds to minutes                              │
│  → Infra needed: all                                      │
└───────────────────────────────────────────────────────────┘
```

The key insight: unit and acceptance tests (the vast majority of your tests) need ZERO external
infrastructure when you have proper test doubles.

## Common mistakes

**Mocking everything (including internals)**: Mock the boundary (ports), not internal collaborators.
Mocking a private method or an internal helper makes tests brittle and coupled to implementation
details. If it is not a port, do not mock it.

**Test doubles with diverging behavior**: If `InMemoryOrderRepositorysitory` silently accepts
duplicate IDs but `PostgresOrderRepository` throws a constraint violation, tests pass but production
breaks. Test doubles must replicate the essential behavior contract of the port.

**Not testing the real implementation**: Test doubles verify that domain logic works. You still need
integration tests that verify `PostgresOrderRepository` correctly maps entities to rows, handles
transactions, and deals with concurrent access. Both test levels are necessary.

**Sharing mutable state between tests**: Each test should get a fresh instance of every test double.
Reusing an `InMemoryOrderRepositorysitory` across tests causes order-dependent failures. Create new
doubles in test setup, never as globals.

**Over-specifying with mocks**: A test that asserts "save was called with exactly these arguments in
this order" is testing implementation, not behavior. Prefer fakes (verify state after the operation)
over mocks (verify call sequence) when possible.

**Putting test doubles in production code**: Doubles implement port interfaces but exist solely for
testing. They belong in `test/doubles/`, never in `src/`. Production code should not depend on test
infrastructure.
