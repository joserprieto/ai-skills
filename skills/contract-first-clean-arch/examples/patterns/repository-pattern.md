# Repository pattern

Decouple domain logic from data access by defining persistence interfaces in the domain layer and
implementing them in infrastructure.

## Problem

Domain logic becomes tightly coupled to data access details: SQL queries, ORM configuration, file
system paths, or API client specifics. This makes the domain impossible to test in isolation and
locks every business rule to a specific storage technology.

When a use case directly calls a database client, changing from one database to another requires
rewriting business logic. Tests become slow and fragile because they need a running database. The
domain layer — which should contain the most valuable and stable code — becomes the most volatile.

## Pattern

Define a **persistence interface (port)** in the domain layer that describes WHAT data operations
the domain needs, without specifying HOW they are performed. Implement this interface in the
infrastructure layer with concrete adapters for each storage technology.

The domain depends on the abstraction. Infrastructure depends on the domain (to implement the
interface). The dependency arrow points inward.

```
┌─────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER                         │
│                                                          │
│  ┌──────────────┐      ┌─────────────────────────────┐  │
│  │ CreateOrder  │─────>│  OrderRepository (port)     │  │
│  │ CancelOrder  │      │                             │  │
│  │              │      │  save(order)                │  │
│  │              │      │  find(id) -> Order?          │  │
│  │              │      │  search(criteria) -> []      │  │
│  └──────────────┘      └──────────────┬──────────────┘  │
│                                       │ interface        │
└───────────────────────────────────────┼─────────────────┘
                                        │
              ┌─────────────────────────┼────────────────────────┐
              │                         │ implements             │
              │         INFRASTRUCTURE LAYER                     │
              │                         │                        │
              │    ┌────────────────────┼───────────────────┐    │
              │    │                    │                   │    │
              │    ▼                    ▼                   ▼    │
              │ ┌──────────┐   ┌──────────────┐   ┌──────────┐ │
              │ │InMemory  │   │ SQL          │   │ File     │ │
              │ │Repository│   │ Repository   │   │ Repository│ │
              │ │          │   │              │   │          │ │
              │ │ HashMap  │   │ PostgreSQL   │   │ JSON on  │ │
              │ │ storage  │   │ queries      │   │ disk     │ │
              │ └──────────┘   └──────────────┘   └──────────┘ │
              │   (tests)       (production)      (development) │
              └─────────────────────────────────────────────────┘
```

## When to use

- Any entity or aggregate that needs to be stored and retrieved
- When you need to test use cases without a running database
- When multiple storage backends are possible (now or in the future)
- When you want to defer the database choice during early development

## Layers involved

| Layer                         | Role                          | Contains                                             |
| ----------------------------- | ----------------------------- | ---------------------------------------------------- |
| `domain/ports/`               | Defines the interface         | `OrderRepository` interface                          |
| `application/`                | Consumes the interface        | `PurchaseOrder`, `AnalyzeFit`                        |
| `infrastructure/persistence/` | Implements the interface      | `PostgresOrderRepository`, `InMemoryOrderRepository` |
| `test/doubles/`               | Provides test implementations | `InMemoryOrderRepository` (may be shared)            |
| Composition root              | Wires implementation to port  | Selects which impl to inject                         |

## Interface design principles

The repository interface should express **domain intent**, not storage mechanics.

**Good interface methods**:

- `save(order)` — persist an order
- `find(id)` — retrieve by identity (the parameter type makes `ById` redundant)
- `search(criteria)` — composable query via Criteria value object (see criteria-pattern.md)
- `next_id()` — identity generation
- `exists(id)` — existence check

**Bad interface methods**:

- `find_by_status(status)` — combinatorial explosion (see criteria-pattern.md)
- `find_by_customer_and_date(id, from, to)` — same problem, worse
- `execute_query(sql)` — leaks SQL
- `find_by_fields(field_map)` — generic, no domain meaning
- `save_and_flush(order)` — leaks ORM concepts
- `get_connection()` — exposes infrastructure

## Multiple implementations

Each implementation serves a different purpose:

**In-memory (testing)**: Uses a simple dictionary or list. Fast, deterministic, no setup required.
Every test suite should use this by default.

**SQL (production)**: Translates port methods into SQL queries. Handles connection pooling,
transactions, and query optimization. This is the only implementation that talks to a real database.

**File-based (development)**: Reads and writes JSON or YAML files. Useful during early development
when the database schema is not yet defined, or for local development without database dependencies.

## Testing strategy

```
Unit tests (fast, isolated):
  Application service + InMemoryRepository → test business logic

Integration tests (slower, real infra):
  SqlRepository + real database → test SQL correctness

Acceptance tests (full workflow):
  Application service + InMemoryRepository + InMemoryEventBus → test full scenarios
```

The in-memory implementation makes unit and acceptance tests fast, deterministic, and independent of
external infrastructure. Integration tests verify that the SQL implementation correctly translates
the port interface to real queries.

## Common mistakes

**Putting query logic in the repository interface**: The interface should reflect domain concepts
("find active orders for this customer"), not query mechanics ("find where status = active AND
customer_id = X"). The SQL translation belongs in the infrastructure implementation.

**Leaking ORM types into the domain**: If the repository returns ORM-managed objects (e.g., with
lazy-loading proxies, dirty tracking), the domain becomes coupled to the ORM. The repository must
return plain domain entities.

**Fat repositories with business logic**: Repositories store and retrieve. They do not validate,
calculate, or enforce business rules. A method like `create_order_and_send_notification()` belongs
in a use case, not a repository.

**Not having an in-memory implementation for tests**: Without it, every test requires a real
database, making the test suite slow and flaky. The in-memory implementation is not optional — it is
a first-class citizen.

**One repository per table**: Repositories should align with aggregates, not database tables. An
`OrderRepository` may internally manage `orders`, `order_items`, and `order_status_history` tables,
but the domain sees only the `Order` aggregate.

**Returning infrastructure-specific errors**: When a SQL query fails, the repository should
translate the error into a domain-meaningful exception (e.g., `OrderNotFound`) rather than bubbling
up a database driver exception.

**Combinatorial explosion of query methods**: Adding `find_by_status()`, `find_by_customer()`,
`find_by_status_and_customer()` and so on creates one method per combination. Use the Criteria
pattern instead: define a value object with optional filter fields and a single `search(criteria)`
method. See criteria-pattern.md.
