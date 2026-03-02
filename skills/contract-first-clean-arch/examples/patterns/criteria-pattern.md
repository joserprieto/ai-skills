# Criteria pattern

Encapsulate search parameters in a domain value object so that repository ports expose a single
`search(criteria)` method instead of one method per query combination.

## Problem

Repository interfaces grow a new method for every query the application needs: `find_by_status`,
`find_by_customer`, `find_by_status_and_customer`, `find_active_since`,
`find_by_customer_and_date_range`... Every combination requires a new signature in the port AND a
new implementation in every adapter (SQL, in-memory, file, API).

This is **combinatorial explosion**. With 5 filterable fields, you can need up to 31 method
signatures. Worse, each new feature ("filter by venue") forces changes across domain, every adapter,
and every test double. The port — which should be stable — becomes the most volatile file in the
project.

## Pattern

Define a **Criteria value object** in the domain layer. It holds optional filter fields that reflect
domain concepts. The repository port exposes a single `search(criteria)` method. Each infrastructure
adapter translates the Criteria into its native query mechanism.

```text
┌─────────────────────────────────────────────────┐
│                  DOMAIN LAYER                   │
│                                                 │
│  OrderSearchCriteria (value object)             │
│  ┌─────────────────────────────────────────┐    │
│  │  status?:    "pending" | "paid" | ...   │    │
│  │  buyerEmail?: string                    │    │
│  │  eventId?:    string                    │    │
│  │  createdAfter?: Date                    │    │
│  │  createdBefore?: Date                   │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  OrderRepository (port)                         │
│  ┌─────────────────────────────────────────┐    │
│  │  find(id) -> Order | null               │    │
│  │  search(criteria) -> Order[]            │    │
│  │  save(order) -> void                    │    │
│  └──────────────────┬──────────────────────┘    │
│                     │ interface                  │
└─────────────────────┼───────────────────────────┘
                      │
     ┌────────────────┼────────────────────┐
     │                │ implements         │
     │     INFRASTRUCTURE LAYER            │
     │                │                    │
     │   ┌────────────┴──────────────┐     │
     │   │                           │     │
     │   ▼                           ▼     │
     │ ┌──────────────┐  ┌────────────────┐│
     │ │ InMemory     │  │ Postgres       ││
     │ │              │  │                ││
     │ │ criteria     │  │ criteria       ││
     │ │  -> JS       │  │  -> WHERE      ││
     │ │    .filter()  │  │    clauses     ││
     │ └──────────────┘  └────────────────┘│
     │   (tests)          (production)     │
     └─────────────────────────────────────┘
```

## When to use

- Any repository with more than one query filter
- When filters are combined freely by the user (search forms, API query parameters, admin panels)
- When the same entity is queried from multiple use cases with different filter combinations
- ACLs that translate domain criteria into external API query parameters (see acl-pattern.md)

## Layers involved

| Layer             | Contains                                           |
| ----------------- | -------------------------------------------------- |
| `domain/`         | Criteria value object definition                   |
| `domain/ports/`   | `search(criteria)` method on the repository port   |
| `application/`    | Use cases build Criteria from input, pass to port  |
| `infrastructure/` | Each adapter translates Criteria to native queries |
| `test/doubles/`   | In-memory adapter filters with language builtins   |

## Translation by adapter

Each adapter translates the same Criteria differently:

**In-memory (tests)**: Filter the internal collection using language-native predicates. Iterate the
stored items and keep those matching all non-null Criteria fields.

**SQL (production)**: Build a WHERE clause dynamically. Each non-null field appends an AND
condition. Use parameterized queries to prevent injection.

**External API (ACL)**: Map Criteria fields to the third-party API's query parameters. Field names
and formats may differ (e.g., domain `createdAfter` becomes API `since_date` in ISO 8601).

## Interface stability

Adding a new filter field requires:

1. Add the optional field to the Criteria value object
2. Handle it in each adapter's translation logic

It does NOT require adding a new method to the port. The port interface `search(criteria)` remains
unchanged. This is why the Criteria pattern keeps ports stable.

Without Criteria, the same change requires a new port method, a new implementation in every adapter,
and a new method in every test double.

## Common mistakes

**Making Criteria fields required instead of optional**: Every field should be optional. A Criteria
with no fields set means "return all". A Criteria with one field set means "filter by that one
dimension". Required fields force callers to provide values they do not care about.

**Leaking infrastructure types into Criteria**: The Criteria is a domain value object. It must not
contain SQL fragments, ORM filter objects, or API-specific field names. It speaks the domain
language.

**Putting Criteria translation in the domain**: The domain defines the Criteria shape. The
infrastructure translates it. A `toSQL()` method on Criteria violates the dependency rule.

**Generic Criteria for all entities**: Each aggregate root gets its own Criteria type.
`OrderSearchCriteria` and `TicketSearchCriteria` are separate value objects, even if they share some
fields. A shared `GenericCriteria<T>` loses type safety and domain meaning.

**Ignoring pagination**: Criteria often pairs with pagination (offset, limit, sort). You can embed
these in the Criteria or pass them as separate parameters. Either way, do not ignore pagination —
unbounded queries will eventually fail.
