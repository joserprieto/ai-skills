---
name: contract-first-clean-arch
description: >-
  Use when starting a new backend or fullstack project, evaluating an existing project's
  architecture, migrating from code-first to contract-first, introducing Clean Architecture layers,
  setting up a type generation pipeline, or assessing architectural maturity. Also use when user
  says "contract-first", "clean architecture", "schema SSOT", "type generation", "ports and
  adapters", "hexagonal architecture", "architecture assessment", "dependency inversion",
  "composition root", "architecture evaluation", "contract-first clean arch", "screaming
  architecture", "vertical slicing", "criteria pattern", or "bounded contexts".
license: MIT
metadata:
  author: Jose R. Prieto (hi [at] joserprieto [dot] es)
  version: '0.3.0'
---

# Contract-First + Clean Architecture

Opinionated, language-agnostic skill for building backend and fullstack projects with
**contract-first schemas as single source of truth**, **Clean Architecture** layering, and
**screaming architecture** that communicates business purpose through structure.

Snippets use TypeScript as notation — the patterns apply to any typed language. See the language
equivalence table below for translations.

## When to use

- Starting a new project that exposes an API (REST, WebSocket, gRPC, GraphQL, events)
- Migrating an existing codebase from code-first to contract-first
- Introducing Clean Architecture layers into a flat/monolithic codebase
- Evaluating architectural maturity of a project
- Integrating external services (LLMs, third-party APIs, databases) with proper abstraction

## When NOT to use

- One-off scripts or throwaway prototypes with no future maintenance
- Projects with fewer than 2 endpoints and no external integrations
- Static sites or pure frontend projects with no backend

## Core principles

These eight principles are non-negotiable regardless of language or framework.

### 1. Contracts are the single source of truth

All types, models, validators, documentation, and client code **must** be derived from a single
schema definition — never maintained independently. Generation pipelines enforce this. Drift
detection in CI verifies it.

**Anti-pattern**: Manually writing type definitions AND schema objects that represent the same data
— they **will** diverge silently.

### 2. Dependencies point inward

Domain code has zero external dependencies. Application code depends only on domain abstractions.
Infrastructure implements domain-defined interfaces. Only the composition root crosses all
boundaries.

```
routes/handlers → use cases (application) → domain ← infrastructure
                                              ↑              |
                                              └──────────────┘
                                           (implements interfaces)
```

### 3. Tests drive design

Write the test first, then the code. If code is hard to test, the architecture is wrong. Port
interfaces, constructor injection, and explicit use cases exist **primarily** to enable testing.

### 4. Domain entities encapsulate behavior

Entities are not data bags. They enforce invariants at construction, own their state transitions,
and make invalid states unrepresentable through value objects and factories.

Domain-specific error hierarchies are mandatory. Every invalid transition or business rule violation
must raise a domain-specific error — never a generic `Error` or `Exception`.

### 5. External service output is untrusted input

Every response from an external service must be parsed, validated against a schema, and handled with
a fallback strategy. This applies regardless of protocol.

### 6. Architecture decisions are documented

ADRs provide governance, onboarding clarity, and a searchable record of why decisions were made.

### 7. The composition root is the single wiring point

One file, one place, assembles the entire dependency graph. Everything else receives its
dependencies through constructors, factory parameters, or framework-native DI mechanisms.

See `examples/snippets/composition-root.ts`.

### 8. Semantic naming — no pattern names in code

Names describe WHAT a thing IS in the domain, never which pattern it implements. Suffixes like
`DTO`, `VO`, `Factory`, `Builder`, `Adapter`, `Handler`, `Wrapper`, `Helper`, `Manager`, `Utils`,
`Impl` are forbidden.

**Allowed exceptions** — where the pattern name IS the semantic name: `*Repository`, `*Mother`,
`*Faker`, `*EventBus`.

Infrastructure adapters are named by technology + domain role: `PostgresOrderRepository`,
`StripePaymentGateway`, `KeycloakAuthService` — NOT `OrderRepositoryImpl` or `PaymentAdapter`.

Entities follow **Tell Don't Ask**: expose behavior (`order.confirm()`), not accessors
(`order.getStatus()`). The entity decides; the caller tells.

See `examples/patterns/project-structure.md` § Semantic naming.

## Agent decision tree

When generating a project, follow this prescriptive sequence. Each step must be completed before the
next.

> **Why contracts first — before even the directory structure?**
>
> In a code-first approach you write entities, then derive the API from them. The API becomes an
> accidental reflection of your internal model. In contract-first, you design the API boundary
> deliberately and THEN build internals to serve it. This has three concrete consequences:
>
> 1. The schemas are **concrete and validatable** (YAML you can lint). Directory names are decisions
>    you can change in seconds. Concrete before abstract.
> 2. The schemas **reveal the slices**. When you write `order.yaml`, `event.yaml`, `ticket.yaml`,
>    `venue.yaml`, the business groupings emerge naturally — you do not invent them, you discover
>    them.
> 3. An agent can **derive structure from schemas** programmatically. It cannot derive schemas from
>    empty directory names. The SSOT must come first because everything else is derived from it.

**Terminology note**: In this skill, "use case" and "application service" are synonyms — both refer
to the orchestration classes in `application/`. The directory name `use-cases/` is forbidden
(pattern name), but the concept is required.

**TDD applies within every step**: Steps 1-8 define the STRUCTURE. Within each step, write the test
first, then the production code. The steps do not mean "build everything first, test last."

### Step 1: Define contract schemas — the SSOT (Contract-First)

**This is the "first" in "contract-first".** Before writing any code or creating any directory
structure, define YAML schemas (JSON Schema Draft 2020-12) for every entity the system will expose
or consume.

The schemas reveal the domain. Writing `order.yaml`, `event.yaml`, `ticket.yaml`, `venue.yaml`
forces you to think about what the system communicates — and the entities that emerge from the
schemas naturally cluster into business capabilities that will become your screaming slices in
Step 3.

See `examples/contracts/schemas/` for real examples and `examples/contracts/specs/` for OpenAPI and
AsyncAPI specifications that reference those schemas.

### Step 2: Set up generation pipeline

Generate types from schemas. The generated files are committed to the repo.

| Ecosystem  | Tool                      | Command                                                           |
| ---------- | ------------------------- | ----------------------------------------------------------------- |
| TypeScript | json-schema-to-typescript | `npx json-schema-to-typescript schemas/*.yaml -o generated/`      |
| Python     | datamodel-codegen         | `datamodel-codegen --input schemas/ --output generated/models.py` |
| Go         | go-jsonschema             | `go-jsonschema -p models schemas/*.yaml`                          |
| Java       | jsonschema2pojo           | Maven/Gradle plugin in build                                      |
| Rust       | schemafy                  | `schemafy schemas/order.yaml`                                     |

Add a `Makefile` target:

```makefile
generate-types:
  npx json-schema-to-typescript contracts/schemas/*.yaml -o contracts/generated/
  @echo "Types regenerated from contract schemas"

check-drift:
  $(MAKE) generate-types
  git diff --exit-code contracts/generated/ || (echo "DRIFT DETECTED" && exit 1)
```

### Step 3: Derive screaming slices from the contracts

Look at the schemas you wrote. The entities cluster into business capabilities. Each cluster becomes
a top-level directory that **screams** what it does.

```
Schemas written in Step 1:          Slices that emerge:
  event.yaml   ─┐
  venue.yaml    ─┤───────────>  src/catalog/
  event-status  ─┘
  order.yaml   ─┐
  ticket.yaml  ─┤───────────>  src/booking/
  order-status  ─┘
  Money, UUID   ─────────────>  src/shared/
```

The contracts REVEAL the structure — you do not invent it.

### Step 4: Create layer structure per slice (Vertical Slicing)

Each slice is **self-contained** with its own layers. No shared `services/` or `repositories/`
directory across slices. Dependencies ALWAYS point inward.

```
{slice}/
├── domain/               # Layer 0: ZERO imports from application/ or infrastructure/
│   ├── entities/         #   Aggregates with state machines and domain events
│   ├── value-objects/    #   Immutable, self-validating (Money, OrderId)
│   ├── ports/            #   Interfaces — define WHAT, never HOW
│   └── errors/           #   Domain-specific error hierarchy
├── application/          # Layer 1: imports ONLY from domain/
│   ├── purchase-order.ts #   Semantic name — NOT use-cases/purchase-order.ts
│   └── analyze-fit.ts    #   Each file orchestrates: load → mutate → persist → publish
└── infrastructure/       # Layer 2: IMPLEMENTS ports from domain/ports/
    ├── persistence/      #   SQL, in-memory, file
    ├── external/         #   ACL for third-party APIs
    └── messaging/        #   Event bus adapters
```

Note: `application/` has NO `use-cases/` subdirectory — that is a pattern name. Files go directly in
`application/` with semantic names. If a slice grows enough that `application/` has many files,
group by business sub-capability:

```
application/
├── purchase/             # "I handle the purchase flow"
│   ├── purchase-order.ts
│   └── refund-order.ts
└── discovery/            # "I handle search and browse"
    └── search-events.ts
```

Only create subdirectories when the grouping reflects a real business boundary — never for
organizational convenience alone.

See `examples/snippets/orchestration.ts` for a concrete application service example.

The generated contract types (from Step 2) live in `contracts/generated/` at the project root — NOT
inside any slice. They are the API boundary shapes. Domain entities inside each slice are
hand-written, with behavior and state machines that no code generator can produce. See
`examples/patterns/project-structure.md` § Generated types vs domain entities for the mapping
between them.

### Screaming Architecture vs Vertical Slicing vs Bounded Context

These are three **independent** architectural decisions that often converge but are NOT synonyms:

| Concept                | Decides                        | Question it answers                          |
| ---------------------- | ------------------------------ | -------------------------------------------- |
| Screaming Architecture | HOW to name directories        | "What does this system do?"                  |
| Vertical Slicing       | WHAT each directory contains   | "Is this slice self-contained?"              |
| Bounded Context (DDD)  | WHERE the model boundaries are | "Where does the ubiquitous language change?" |

In most projects, a screaming slice corresponds to a Bounded Context. But:

- A BC can contain multiple slices (e.g., `order-creation/` and `order-fulfillment/` within the same
  Ordering BC)
- A slice can exist without being a DDD Bounded Context (e.g., `notification/` may be a technical
  slice, not a domain model boundary)

Start with screaming slices derived from your contracts. If the domain is complex enough to need DDD
modeling, the BC boundaries will emerge from the ubiquitous language — not from the directory
structure.

### Step 5: Define port interfaces with Criteria pattern

For every external dependency, define a port interface in `domain/ports/`. Domain entities (written
by hand) model the internal behavior. Port interfaces define the boundaries between the domain and
the outside world.

**CRITICAL: search operations MUST use the Criteria pattern** — a domain value object for composable
filters. NEVER add `find_by_city()`, `find_by_capacity()` methods to ports. That creates
combinatorial explosion. One `search(criteria)` method covers all cases.

Adding a new filter = adding a field to Criteria. NOT changing the port signature.

See `examples/snippets/port-interface.ts` and `examples/patterns/criteria-pattern.md`.

### Step 6: Implement infrastructure adapters

For each port, create at least TWO implementations:

- In-memory (fake for tests)
- Production (SQL, HTTP, SDK)

See `examples/snippets/repository-implementation.ts` and `examples/snippets/acl-translation.ts`.

### Step 7: Wire in composition root

See `examples/snippets/composition-root.ts`. One file imports all concrete infrastructure. Override
mechanism for tests.

### Step 8: Build test infrastructure

Create Object Mothers with faker for domain-meaningful test data. Create stubs and spies for port
interfaces.

See `examples/snippets/object-mother.ts` and `examples/snippets/test-double-stub-spy.ts`.

## Language equivalence table

Snippets use TypeScript as notation. Apply this table for other languages:

| Concept         | TypeScript                | Python                          | Go                       | Java/Kotlin                      | Rust                        |
| --------------- | ------------------------- | ------------------------------- | ------------------------ | -------------------------------- | --------------------------- |
| Port interface  | `interface`               | `ABC` + `@abstractmethod`       | `interface` (implicit)   | `interface`                      | `trait`                     |
| Value object    | `class` (readonly fields) | `@dataclass(frozen=True)`       | `struct` (no setters)    | `record` / `final class`         | `struct` (no `mut`)         |
| Entity          | `class` (private state)   | `class` (private attrs)         | `struct` + methods       | `class` (private fields)         | `struct` + `impl`           |
| Async operation | `Promise<T>`              | `async/await` (asyncio)         | goroutine + channel      | `CompletableFuture<T>`           | `async fn -> impl Future`   |
| DI mechanism    | Constructor params        | `__init__` params / `Depends()` | `func` params / `main()` | `@Inject` / constructor          | Generics / `main()`         |
| Error hierarchy | `class extends Error`     | `class(DomainError)`            | Custom error types       | `class extends RuntimeException` | `enum` implementing `Error` |
| File naming     | `kebab-case.ts`           | `snake_case.py`                 | `snake_case.go`          | `PascalCase.java`                | `snake_case.rs`             |
| Criteria        | `interface XxxCriteria`   | `@dataclass XxxCriteria`        | `struct XxxCriteria`     | `record XxxCriteria`             | `struct XxxCriteria`        |
| Test double     | `class implements Port`   | `class(PortABC)`                | `struct` + methods       | `class implements Port`          | `struct` + `impl Trait`     |
| Object Mother   | Static factory methods    | `@classmethod`                  | Package-level funcs      | Static factory methods           | Associated functions        |
| Faker library   | `@faker-js/faker`         | `faker`                         | `go-faker`               | `javafaker` / `datafaker`        | `fake`                      |

## Screaming architecture rules

Directory names communicate BUSINESS PURPOSE at every level — not technical patterns.

```
# BAD — pattern jargon at every level
src/
├── controllers/
├── services/
│   └── use-cases/        # ← pattern name inside pattern name
├── repositories/
├── dtos/                 # ← pattern suffix as directory
└── models/

# GOOD — screams business at the top, layers inside each slice
src/
├── catalog/              # "I manage events and venues"
│   ├── domain/
│   ├── application/      # Files here, not in use-cases/ subdir
│   └── infrastructure/
├── booking/              # "I handle reservations and payments"
│   ├── domain/
│   ├── application/
│   └── infrastructure/
└── shared/               # Cross-cutting value objects and ports
```

The rule applies at EVERY directory depth:

- **Top level**: business capabilities (`catalog/`, `booking/`) — NOT frameworks
- **Second level**: architectural layers (`domain/`, `application/`) — these are acceptable because
  they describe the dependency direction, not a pattern name
- **Inside layers**: semantic names — `purchase-order.ts`, NOT `use-cases/`, NOT `dtos/`, NOT
  `helpers/`

## Testing strategy

The testing strategy is NOT a methodology choice — it is a **consequence of the architecture**.
Ports & adapters determines what is testable, how fast, and at what granularity. The distribution of
tests emerges from the layers:

| Layer          | What to test                              | How                        | Speed           |
| -------------- | ----------------------------------------- | -------------------------- | --------------- |
| Domain         | State machines, invariants, value objects | Direct calls, no DI        | Microseconds    |
| Application    | Business operations through ports         | In-memory doubles injected | Milliseconds    |
| Infrastructure | SQL, HTTP clients, serialization          | Real DB / API sandbox      | Seconds         |
| E2E            | Critical user journeys only               | Full system wired          | Seconds-minutes |
| Contracts      | Schema ↔ type drift                       | CI pipeline                | Seconds         |

The key insight: the application layer tests are fast AND high-confidence because the architecture
gives you injectable ports. Without ports & adapters, you would need real infrastructure for the
same confidence level — making those tests slow and flaky. The architecture makes the testing
strategy possible; the testing strategy does not dictate the architecture.

Test data is generated via Object Mothers with faker (see Step 8) — keeping domain-meaningful
fixtures separate from test logic and making tests read as business scenarios: `OrderMother.paid()`
instead of manual object construction.

## Frontend adaptation

When applying Clean Architecture to a frontend project, adapt the layers:

| Backend layer   | Frontend equivalent | Responsibility                                        |
| --------------- | ------------------- | ----------------------------------------------------- |
| domain/         | domain/ (or rules/) | Pure types + business rules, ZERO framework imports   |
| domain/ports/   | domain/ports/       | Repository/service interfaces (inside domain/)        |
| infrastructure/ | infrastructure/     | HTTP fetch implementations                            |
| application/    | stores/             | State management with DI (receives ports via factory) |
| api/            | components/         | UI components consuming stores + domain rules         |

**Screaming slices apply equally**: top-level directories are feature slices (event-discovery/,
booking/), not technical layers.

**Import rules within a slice:**

```
components/ → stores/ → domain/ports/ → domain/
                             ↑
           infrastructure/ ──┘ (implements ports)
```

Components NEVER import from infrastructure/. Cross-slice imports go through ports only.

See `examples/snippets/frontend-store-with-di.ts` (React/Zustand-specific).

## Project structure template

```
project-root/
├── contracts/                  # SSOT: schema definitions + generation
│   ├── schemas/                # Source schemas (YAML, JSON Schema Draft 2020-12)
│   ├── specs/                  # OpenAPI, AsyncAPI specs
│   └── generated/              # AUTO-GENERATED output (committed)
├── src/
│   ├── {slice}/                # Screaming: catalog/, booking/, notification/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── value-objects/
│   │   │   ├── ports/          # Interfaces with Criteria for search ops
│   │   │   └── errors/
│   │   ├── application/            # Semantic file names — NO use-cases/ subdir
│   │   └── infrastructure/
│   │       ├── persistence/
│   │       ├── external/       # ACLs for third-party APIs
│   │       └── messaging/
│   ├── shared/
│   │   ├── domain/             # Value objects (Money, IDs), EventBus port
│   │   └── infrastructure/     # Shared adapters (event bus, notifications)
│   ├── api/                    # Thin HTTP/gRPC handlers
│   └── composition-root.*     # Single wiring point
├── test/
│   ├── mothers/                # Object Mothers (use faker internally)
│   ├── doubles/                # Stubs + spies for port interfaces
│   └── contract/               # Schema ↔ type alignment tests
└── Makefile                    # generate-types, check-drift, test targets
```

## Self-assessment checklist

Use this to evaluate any project. Each "no" identifies a specific gap:

| #   | Question                                                                           | Principle              | Priority |
| --- | ---------------------------------------------------------------------------------- | ---------------------- | -------- |
| 1   | Are all types derived from a single schema source via code generation?             | Contract SSOT          | P1       |
| 2   | Does CI fail if generated files are stale (drift detection)?                       | Drift Protection       | P1       |
| 3   | Can you swap any external dependency without modifying domain or application code? | Dependency Inversion   | P1       |
| 4   | Does every external service have a port interface with at least one test double?   | Port/Adapter           | P1       |
| 5   | Are application services explicit classes/functions, separate from HTTP handlers?  | App Layer Explicitness | P2       |
| 6   | Do domain entities enforce their own invariants via guarded state transitions?     | Domain Richness        | P2       |
| 7   | Are there value objects for domain identifiers and measurements?                   | Value Objects          | P2       |
| 8   | Is there a composition root — one file where the dependency graph is assembled?    | Composition Root       | P1       |
| 9   | Do port search operations use the Criteria pattern (not combinatorial methods)?    | Criteria Pattern       | P2       |
| 10  | Are there Object Mothers with faker for test data?                                 | Test Maintainability   | P2       |
| 11  | Is every architecture decision documented in an ADR?                               | Governance             | P3       |
| 12  | Is the dev environment reproducible with a single command?                         | DX                     | P3       |
| 13  | Does CI enforce linting, type checking, testing, and contract validation?          | Quality Gates          | P2       |
| 14  | For external APIs: Is every response validated against a schema before use?        | External Safety        | P1       |
| 15  | Does the directory structure scream business purpose, not framework names?         | Screaming Arch         | P2       |
| 16  | Are all names semantic (no DTO/VO/Helper/Impl suffixes)? Tell Don't Ask?           | Semantic Naming        | P2       |

## Common mistakes

| Mistake                                                               | Why it's wrong                       | What to do instead                                                              |
| --------------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------- |
| Writing types AND schemas independently                               | They diverge silently                | Generate types FROM schemas                                                     |
| Business logic in route handlers                                      | Untestable, grows into god functions | Extract to application services with injected ports                             |
| Importing concrete services in domain                                 | Violates dependency rule             | Define port interfaces, inject via constructor                                  |
| `find_by_X()` methods on repositories                                 | Combinatorial explosion              | Criteria pattern: one `search(criteria)` method                                 |
| Layer-based top-level dirs (controllers/, services/)                  | Hides business purpose               | Screaming slices (catalog/, booking/)                                           |
| Tests that require real external services                             | Slow, flaky, non-deterministic       | In-memory fakes implementing port interfaces                                    |
| Generic errors for domain violations                                  | Loses business context               | Domain error hierarchy with ubiquitous language                                 |
| Coupling domain to ORM/framework                                      | Domain depends on infrastructure     | Pure domain classes; map in infrastructure                                      |
| No generation pipeline for contracts                                  | "Contract-first" in name only        | Makefile target: schema → types → drift check                                   |
| Pattern names in classes (`OrderDTO`, `PaymentAdapter`, `UserHelper`) | Hides domain intent behind jargon    | Semantic names: `CreateOrderRequest`, `StripePaymentGateway`, methods on `User` |
| Frontend components importing from infrastructure/                    | Leaks HTTP details into UI           | Components import stores + domain, never infrastructure                         |

## Scoring rubric

When evaluating a project, score each sub-concern 1-5:

| Score | Meaning   | Evidence                                  |
| ----- | --------- | ----------------------------------------- |
| 1     | Absent    | No evidence of the practice               |
| 2     | Minimal   | Partial or accidental implementation      |
| 3     | Partial   | Intentional but incomplete adoption       |
| 4     | Solid     | Consistent implementation with minor gaps |
| 5     | Exemplary | Comprehensive, documented, enforced in CI |

### Evaluation concerns

| Area                   | Sub-concerns to score                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| Contract-First         | Contract SSOT, Type Generation, Drift Protection, Contract Testing                    |
| Clean Architecture     | Domain Layer, Application Layer, Infra Abstraction, Dependency Rule, Composition Root |
| Screaming Architecture | Business-purpose dirs, Slice self-containment, No cross-slice shared services/        |
| Testing                | Layer-appropriate tests, Isolation via ports, Contract tests, Object Mothers          |
| DDD                    | Ubiquitous Language, Aggregates, Value Objects, Domain Events, Criteria               |
| Integration            | ACL pattern, External validation, Resilience patterns                                 |

## Examples directory

See `examples/` for complete working examples organized in three subdirectories:

- **`contracts/`** — Real YAML schemas (JSON Schema Draft 2020-12), OpenAPI 3.1.0, and AsyncAPI 3.0.0 specs
- **`patterns/`** — Language-agnostic architecture patterns (criteria, ACL, repository, strategy, infrastructure doubling)
- **`snippets/`** — Architecture patterns as TypeScript notation (entity, value object, port, repository, composition root, test doubles, Object Mother, frontend store)
