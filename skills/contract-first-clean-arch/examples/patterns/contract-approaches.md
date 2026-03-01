# Contract approaches: detailed guidance

This document explains when and how to use each contract strategy, independent of
language or framework.

## Decision matrix

Choose your contract approach based on your API style and team ecosystem:

```
                        ┌─────────────────────────┐
                        │   What is your primary   │
                        │   API communication?     │
                        └────────┬────────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                   │
         REST/HTTP          Events/Msgs        RPC/Streaming
              │                  │                   │
        ┌─────┴─────┐    ┌──────┴──────┐     ┌──────┴──────┐
        │  OpenAPI   │    │  AsyncAPI   │     │  Protobuf   │
        │  3.x spec  │    │  3.0 spec   │     │  .proto     │
        └─────┬─────┘    └──────┬──────┘     └──────┴──────┘
              │                  │                   │
     ┌────────┴────────┐        │           ┌───────┴───────┐
     │ Need types only │        │           │ protoc + lang  │
     │ across languages│        │           │ specific plugin│
     │ without API?    │        │           └───────────────┘
     └────────┬────────┘        │
              │                 │
        ┌─────┴─────┐          │
        │ JSON Schema│          │
        │  (standalone)│        │
        └───────────┘          │
                               │
                    ┌──────────┴──────────┐
                    │  GraphQL?           │
                    │  → SDL schema       │
                    │  (.graphql files)   │
                    └─────────────────────┘
```

## Approach 1: OpenAPI (REST APIs)

**Schema source**: `openapi.yaml` (version 3.0 or 3.1)

**What it defines**: Endpoints, request/response schemas, authentication, error responses,
pagination, headers.

**Generates**:

- Server stubs (route definitions with typed handlers)
- Client SDKs (typed API clients)
- Types/models in any language
- Interactive documentation (Swagger UI, Redoc)
- Contract tests (response shape validation)

**Tools by ecosystem**:

| Ecosystem   | Generator                                          | Output                               |
|-------------|----------------------------------------------------|--------------------------------------|
| TypeScript  | `openapi-typescript`, `orval`, `openapi-generator` | Types, Axios/fetch clients           |
| Python      | `datamodel-codegen`, `openapi-generator`            | Pydantic models, client classes      |
| Java/Kotlin | `openapi-generator`                                | POJOs/data classes, Retrofit clients |
| Go          | `oapi-codegen`, `openapi-generator`                | Structs, Chi/Gin handlers            |
| C#          | `NSwag`, `openapi-generator`                       | Types, HttpClient clients            |

**Drift detection**:

```bash
# CI step: regenerate and check for uncommitted changes
openapi-generator generate -i openapi.yaml -g typescript-fetch -o generated/
git diff --exit-code generated/
```

## Approach 2: AsyncAPI (events and messaging)

**Schema source**: `asyncapi.yaml` (version 3.0)

**What it defines**: Channels, message schemas, event payloads, protocol bindings
(AMQP, NATS, Kafka, WebSocket, MQTT).

**Generates**:

- Event type definitions
- Publisher/subscriber stubs
- Channel documentation
- Message validators

**When to use**: Any project with event-driven communication — message queues, pub/sub,
WebSocket events, server-sent events.

**Tools by ecosystem**:

| Ecosystem  | Generator                            | Output                              |
|------------|--------------------------------------|-------------------------------------|
| TypeScript | `@asyncapi/generator` with templates | Types, NATS/Kafka clients           |
| Python     | `@asyncapi/generator`, custom        | Pydantic event models               |
| Java       | `@asyncapi/generator`                | POJOs, Spring Cloud Stream bindings |

**Combines with**: OpenAPI for REST + AsyncAPI for events in the same project.
Both specs can reference shared schemas via `$ref` to a common `schemas/` directory.

## Approach 3: JSON Schema (language-agnostic types)

**Schema source**: `.json` or `.yaml` files following JSON Schema draft 2020-12

**What it defines**: Data structures, validation rules, type constraints.
Does NOT define endpoints, channels, or protocols.

**Generates**:

- Types in ANY language (the most portable option)
- Validators in ANY language
- Form schemas for UI generation

**When to use**: When you need shared types across multiple languages or services
without coupling to a specific API protocol.

**Tools by ecosystem**:

| Ecosystem  | Generator                        | Output                         |
|------------|----------------------------------|--------------------------------|
| TypeScript | `json-schema-to-typescript`, `quicktype` | Interfaces, type guards        |
| Python     | `datamodel-codegen`                      | Pydantic models, dataclasses   |
| Java       | `jsonschema2pojo`                | POJOs with Jackson annotations |
| Go         | `go-jsonschema`                  | Structs with json tags         |
| C#         | `NJsonSchema`                    | Types with DataAnnotations     |

**Key advantage**: OpenAPI and AsyncAPI both use JSON Schema internally. Standalone
JSON Schema files can be `$ref`'d from both specs, creating a unified type system
across REST and event APIs.

## Approach 4: Protocol Buffers (gRPC / high-performance RPC)

**Schema source**: `.proto` files (proto3)

**What it defines**: Services, methods, request/response messages, field types.

**Generates**:

- Typed client and server stubs in any language
- Serialization/deserialization code
- gRPC service definitions

**When to use**: High-performance inter-service communication, streaming,
strongly-typed RPC across language boundaries.

**Built-in generation**: `protoc` compiler with language-specific plugins.
No custom pipeline needed — the toolchain is standardized.

## Approach 5: GraphQL SDL (GraphQL APIs)

**Schema source**: `.graphql` files (Schema Definition Language)

**What it defines**: Types, queries, mutations, subscriptions, input types.

**Generates**:

- Typed resolvers (server)
- Typed query hooks/clients (frontend)
- Type definitions in any language

**Tools**: `graphql-codegen` (TypeScript), `ariadne-codegen` (Python),
`graphql-java-codegen` (Java).

## Combining approaches

Most mature projects combine multiple approaches:

| Pattern          | REST API    | Events          | Shared types                 |
|------------------|-------------|-----------------|------------------------------|
| Common           | OpenAPI     | AsyncAPI        | JSON Schema `$ref`'d by both |
| gRPC-native      | —           | Protobuf events | `.proto` definitions         |
| GraphQL + events | GraphQL SDL | AsyncAPI        | Shared type definitions      |

**Key rule**: All specs must reference the SAME schema definitions. Never duplicate
type definitions across specs — use `$ref` or imports to a shared `schemas/` directory.

## Anti-patterns

| Anti-pattern                                          | Why it fails                                      | Correct approach                    |
|-------------------------------------------------------|---------------------------------------------------|-------------------------------------|
| Writing types by hand in each language                | N languages × M types = N×M things to sync        | Generate from single schema         |
| Separate OpenAPI and AsyncAPI with duplicated schemas | Schemas will diverge between REST and event types | Shared `schemas/` dir with `$ref`   |
| Using Zod/Pydantic as SSOT in polyglot projects       | Locks the schema to one language                  | Use JSON Schema or Protobuf as SSOT |
| No drift detection in CI                              | Generated code goes stale silently                | `generate && git diff --exit-code`  |
| Treating OpenAPI as documentation only                | Specs that don't generate code become outdated    | Generate code FROM the spec         |
