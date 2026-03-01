# Event Ticketing Platform — Contract SSOT

This directory is the **Single Source of Truth (SSOT)** for the Event Ticketing Platform domain. Every type, endpoint,
and domain event is defined here first; implementation code is then generated from these contracts.

## Why contracts first?

When contracts live in code, the schema and the implementation inevitably drift apart. By treating YAML schemas as the
authoritative source, we guarantee that server stubs, client SDKs, and documentation always agree on the shape of the
data.

## Directory structure

```
contracts/
├── schemas/            # Domain types (JSON Schema Draft 2020-12)
│   ├── common.yaml     # Shared building blocks (Money, UUID, DateTime, ...)
│   ├── event.yaml      # Event aggregate
│   ├── ticket.yaml     # Ticket entity with status lifecycle
│   ├── order.yaml      # Order aggregate (groups tickets into a purchase)
│   └── venue.yaml      # Venue value object
├── specs/              # Interface definitions
│   ├── openapi.yaml    # Synchronous HTTP API (OpenAPI 3.1.0)
│   └── asyncapi.yaml   # Asynchronous domain events (AsyncAPI 3.0.0)
└── README.md
```

## How `$ref` links everything together

Schemas reference each other through **relative `$ref` paths**:

- `event.yaml` references `common.yaml#/$defs/UUID` for its `id` field.
- `openapi.yaml` references `../schemas/event.yaml` for response bodies.
- `asyncapi.yaml` references `../schemas/common.yaml#/$defs/Money` for the payment amount.

This means a change to a shared type (e.g. adding a currency to the `Currency` enum) propagates automatically to every
schema and spec that uses it.

## Generation flow

```
schemas/*.yaml ──┐
                 ├──▶ generation script ──▶ language-specific types
specs/*.yaml ────┘        (e.g. openapi-generator, asyncapi-generator)
```

1. **Edit** the YAML contracts in this directory.
2. **Run** the generation script (e.g. `make generate`).
3. **Review** the generated types in `contracts/generated/` (or equivalent).
4. **Implement** business logic against the generated interfaces.

Generated code should be committed to the repository so that consumers who do not run the generator locally still have
up-to-date types.

## Drift detection in CI

Add a CI step that regenerates the code and checks for uncommitted differences:

```yaml
# Example GitHub Actions step
- name: Detect contract drift
  run: |
    make generate
    git diff --exit-code contracts/generated/
```

If the diff is non-empty, the build fails — proving that someone changed the implementation without updating the
contract (or vice versa).

## Adding a new entity

1. Create `schemas/<entity>.yaml` with `$schema` and `$id`.
2. Reference shared types from `common.yaml` via `$ref`.
3. Add endpoints to `specs/openapi.yaml` and/or channels to `specs/asyncapi.yaml`.
4. Re-run the generator and verify that tests still pass.
