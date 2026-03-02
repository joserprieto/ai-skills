# Project structure: language-agnostic layers

This document defines the conceptual layer structure independent of any language, framework, or
tooling. Use this as the blueprint; adapt directory names and conventions to your ecosystem.

## Layer architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      CONTRACTS                              │
│  Schema definitions (SSOT), generation pipeline, specs      │
│  → Isolated module, consumed by all other layers            │
└─────────────────────┬───────────────────────────────────────┘
                      │ generates
┌─────────────────────▼───────────────────────────────────────┐
│                      API / HANDLERS                         │
│  Thin adapters: HTTP routes, gRPC handlers, GraphQL         │
│  resolvers, CLI commands, WebSocket handlers                │
│  → Parse input, call application service, format output     │
│  → NO business logic                                        │
├─────────────────────┬───────────────────────────────────────┤
│                      APPLICATION                            │
│  One class/function per business operation                   │
│  → Orchestrate domain objects + ports                       │
│  → Depend ONLY on domain interfaces (ports)                 │
├─────────────────────┬───────────────────────────────────────┤
│                      DOMAIN (innermost)                     │
│  Entities, Value Objects, Domain Events, Port interfaces     │
│  → ZERO external dependencies                               │
│  → Pure business rules and invariants                       │
├─────────────────────┬───────────────────────────────────────┤
│                      INFRASTRUCTURE                         │
│  Concrete implementations of domain ports                   │
│  → Database adapters, API clients, SDK wrappers             │
│  → Depends on domain interfaces, implements them            │
└─────────────────────┬───────────────────────────────────────┘
                      │ assembled by
┌─────────────────────▼───────────────────────────────────────┐
│                  COMPOSITION ROOT                           │
│  Single file: instantiates infrastructure, wires into       │
│  application services, registers handlers                   │
│  → The ONLY place that crosses all layer boundaries         │
└─────────────────────────────────────────────────────────────┘
```

## Abstract directory structure

This shows the layers within a single slice (or a small project that is itself one slice). In a
multi-slice project, nest this structure under each screaming slice directory — see § Bounded
Context organization below.

```
project-root/
├── contracts/                  # SSOT for all types
│   ├── schemas/                # Source: YAML, JSON Schema, .proto, .graphql
│   ├── specs/                  # OpenAPI, AsyncAPI specifications
│   ├── scripts/                # Generation pipeline
│   ├── generated/              # AUTO-GENERATED output (committed)
│   └── tests/                  # Contract tests (schema ↔ type alignment)
│
├── src/
│   ├── domain/                 # Innermost layer — ZERO external deps
│   │   ├── entities/           # Rich domain objects with behavior
│   │   ├── value-objects/      # Self-validating, immutable types
│   │   ├── events/             # Domain event definitions
│   │   └── ports/              # Interfaces for external services
│   │
│   ├── application/            # Depends only on domain — NO use-cases/ subdir
│   │   ├── purchase-order.*    # Semantic name for each business operation
│   │   └── analyze-fit.*       # Files directly in application/
│   │
│   ├── infrastructure/         # Concrete implementations
│   │   ├── persistence/        # Repository implementations (DB, file, etc.)
│   │   ├── external/           # API clients, SDK wrappers
│   │   └── messaging/          # Event bus, message queue implementations
│   │
│   ├── api/                    # Thin handlers (HTTP, gRPC, GraphQL, CLI)
│   │   ├── routes/             # HTTP endpoints (REST)
│   │   ├── handlers/           # gRPC/WebSocket handlers
│   │   └── middleware/         # Cross-cutting concerns
│   │
│   └── composition-root.*      # Single wiring point (main/app entry)
│
├── test/
│   ├── mothers/                # Object Mothers (use faker internally)
│   ├── doubles/                # Test doubles (stubs, fakes, spies)
│   ├── contract/               # Schema ↔ type alignment tests
│   └── acceptance/             # Full workflow tests with faked infra
│
└── docs/
    └── architecture/
        ├── adrs/               # Architecture Decision Records
        └── diagrams/           # Architectural diagrams
```

## Contract-first pipeline

The `contracts/` module is where "contract-first" becomes real. It contains the schema definitions,
the generation scripts, and the generated output. Everything else in the project consumes this
output — never the raw schemas directly.

### The flow

```text
 1. AUTHOR              2. GENERATE               3. DERIVE SLICES
 ─────────              ──────────                ──────────────

 contracts/             contracts/generated/       Schemas cluster into
   schemas/               │                        business capabilities:
     order.yaml ──┐       ├── typescript/
     event.yaml ──┤       │     order.d.ts          order + ticket → booking/
     venue.yaml ──┘       │     event.d.ts          event + venue  → catalog/
     ticket.yaml          │                         Money, UUID    → shared/
                    │     └── python/
                    │           order.py           The contracts REVEAL the
                    │           event.py           structure — you do not
                    │                              invent it.
              contracts/scripts/
                generate-types.sh
                (calls each ecosystem tool)

 4. CONSUME             5. VALIDATE             6. PROTECT
 ─────────              ──────────              ──────────
 Generated types are    test/contract/          CI pipeline:
 DATA SHAPES (no          schema-alignment.*      make generate-types
 behavior). Domain        (generated types        git diff --exit-code
 entities are HAND-        match schema)           generated/
 WRITTEN (with state                               → fails if stale
 machines). The API
 handler maps between
 them (see § Generated
 types vs domain
 entities below).

 Same schemas, multiple consumers. The schemas are the
 SSOT — each consumer generates types for its language.
```

The schemas are language-agnostic. Each consumer (backend, frontend, mobile, another service)
generates types for its own ecosystem from the same source. A monorepo with a Python backend and a
TypeScript frontend generates both `models.py` and `types.d.ts` — that is the point of
contract-first.

### What each directory contains

**`contracts/schemas/`** — Source of truth. YAML files using JSON Schema Draft 2020-12. One file per
entity or aggregate. Use `$ref` for shared definitions (e.g., `common.yaml` defines Money, UUID).
These files are written by humans. Everything else is derived.

**`contracts/specs/`** — API specifications that reference the schemas. OpenAPI 3.1.0 for REST
endpoints, AsyncAPI 3.0.0 for event channels. The specs use `$ref` to point at schemas — they never
duplicate type definitions.

**`contracts/scripts/`** — Generation scripts. Each script calls the ecosystem-specific tool to
transform schemas into language types. The script is a thin wrapper — the tool does the work:

| Ecosystem  | Tool                      | Input            | Output                 |
| ---------- | ------------------------- | ---------------- | ---------------------- |
| TypeScript | json-schema-to-typescript | `schemas/*.yaml` | `generated/types.d.ts` |
| Python     | datamodel-codegen         | `schemas/`       | `generated/models.py`  |
| Go         | go-jsonschema             | `schemas/*.yaml` | `generated/models.go`  |
| Java       | jsonschema2pojo           | `schemas/`       | `generated/*.java`     |

**`contracts/generated/`** — Auto-generated output. These files are **committed to the repo** so
that consumers do not need to run the generation tool. They are regenerated by CI and checked for
drift.

**`contracts/tests/`** — Contract tests. They verify that the generated types match the schema
definitions. If a field is added to the schema but the types are not regenerated, the test fails.

### Generated types vs domain entities

Generated types and domain entities serve different purposes. They are NOT the same thing:

```text
┌─────────────────────────────┐  ┌─────────────────────────────┐
│  GENERATED TYPES (contract) │  │  DOMAIN ENTITIES (behavior) │
│                             │  │                             │
│  - Data shapes              │  │  - State machines           │
│  - Validation schemas       │  │  - Business rules           │
│  - API request/response     │  │  - Invariant enforcement    │
│  - NO behavior              │  │  - Domain events            │
│  - Auto-generated           │  │  - Hand-written             │
│                             │  │                             │
│  Example names:             │  │  Example names:             │
│  CreateOrderRequest         │  │  Order                      │
│  OrderResponse              │  │  Money                      │
│  FitAnalysisResult          │  │  InterviewSession           │
│                             │  │                             │
│  Live in:                   │  │  Live in:                   │
│  contracts/generated/       │  │  src/domain/entities/       │
└──────────────┬──────────────┘  └──────────────┬──────────────┘
               │                                │
               └───────────┐  ┌─────────────────┘
                           │  │
                    ┌──────▼──▼──────┐
                    │   MAPPING      │
                    │                │
                    │  API handler   │
                    │  maps between  │
                    │  contract type │
                    │  and domain    │
                    │  entity        │
                    └────────────────┘
```

The API handler (or a mapper in infrastructure) converts between the two worlds:

- **Inbound**: Parse request body → validate against generated schema → map to domain entity (call
  factory/constructor)
- **Outbound**: Domain entity → map to contract type → serialize as response

Domain entities are NEVER auto-generated. They contain behavior, state machines, and invariants that
no code generator can produce. Generated types are data shapes at the API boundary.

### Drift detection in CI

Add a CI step that regenerates types and checks for uncommitted changes:

```text
Pipeline step: check-contract-drift
  1. Run generation script (same as local)
  2. git diff --exit-code contracts/generated/
  3. If diff exists → FAIL with "Contract drift detected"
  4. If no diff → PASS
```

This catches two failure modes:

- Someone edited the schema but did not regenerate types
- Someone edited generated types manually (forbidden)

## Semantic naming (mandatory)

Names describe WHAT a thing IS in the domain — never which design pattern it implements. This is a
hard rule, not a preference.

### The rule

Class names, interface names, file names, and variable names use **domain language**. Pattern names
(DTO, VO, Factory, Builder, Adapter, Handler, Wrapper, Helper, Manager, Utils, Impl) are forbidden
as suffixes or prefixes.

```text
BAD                              GOOD
───                              ────
OrderDTO                         CreateOrderRequest
OrderVO                          Money
OrderFactory                     Order.create(...)
PaymentAdapter                   StripePaymentGateway
EmailHelper                      EmailSender
OrderMapper                      (inline in handler)
UserUtils                        (methods on User entity)
DatabaseImpl                     PostgresOrderRepository
```

The name should answer "what is this in the business domain?" not "which Gang of Four pattern does
this implement?"

### Allowed exceptions

Some pattern names ARE the semantic name — the pattern IS the domain concept:

| Allowed suffix      | Why                                                   | Example            |
| ------------------- | ----------------------------------------------------- | ------------------ |
| `*Repository`       | "repository" IS what it does (stores/retrieves)       | `OrderRepository`  |
| `*Mother`           | "mother" IS what it does (creates test fixtures)      | `OrderMother`      |
| `*Faker` / `Faker*` | "faker" IS what it does (generates random data)       | `OrderFaker`       |
| `*EventBus`         | "event bus" IS what it does (publishes domain events) | `InMemoryEventBus` |

### Infrastructure implementations

Infrastructure adapters are named by WHAT TECHNOLOGY they use, not by what pattern they implement:

```text
BAD                              GOOD
───                              ────
OrderRepositoryImpl              PostgresOrderRepository
PaymentServiceAdapter            StripePaymentGateway
AuthServiceWrapper               KeycloakAuthService
CacheDecorator                   RedisSessionCache
```

The prefix (Postgres, Stripe, Keycloak, Redis) tells you the technology. The suffix (Repository,
Gateway, Service, Cache) tells you the domain role. Together they scream "I am the Stripe
implementation of the payment gateway port."

### Tell Don't Ask

Domain entities expose behavior, not data. Methods describe actions, not accessors:

```text
BAD (Ask)                        GOOD (Tell)
─────────                        ───────────
order.getStatus()                order.confirm()
if (order.isPaid()) ...          order.pay(paymentId)
order.setStatus('cancelled')     order.cancel(reason)
order.getData()                  order.pullDomainEvents()
```

The caller TELLS the entity what to do. The entity decides whether the transition is valid and
raises a domain error if not. The caller never inspects internal state to make decisions that belong
to the entity.

## Layer dependency rule

The **only** valid import direction is **inward**:

```
api → application → domain ← infrastructure
                      ↑            |
                      └────────────┘
                   (implements interfaces)
```

**Forbidden imports**:

- domain → infrastructure (domain NEVER imports concrete implementations)
- domain → api (domain NEVER knows about HTTP/gRPC)
- application → api (use cases NEVER know about HTTP/gRPC)
- application → infrastructure (use cases NEVER import concrete classes)

**Allowed imports**:

- api → application (handlers call use cases)
- application → domain (application services use entities, value objects, ports)
- infrastructure → domain (adapters implement port interfaces)
- composition-root → everything (the only boundary-crossing point)

## Bounded Context organization (for larger projects)

When a project grows beyond a single domain, organize by Bounded Context:

```
src/
├── contexts/
│   ├── catalog/                # BC: Catalog
│   │   ├── domain/
│   │   ├── application/
│   │   └── infrastructure/
│   ├── booking/                # BC: Booking
│   │   ├── domain/
│   │   ├── application/
│   │   └── infrastructure/
│   └── shared/                 # Shared kernel
│       ├── domain/
│       └── infrastructure/
├── api/                        # Unified API layer
└── composition-root.*
```

Each BC is self-contained with its own domain, application, and infrastructure layers. BCs
communicate through domain events or application-level integration, never by importing each other's
domain classes directly.
