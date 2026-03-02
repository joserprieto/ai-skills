# Anti-Corruption Layer pattern

Protect your domain model from external system shapes by translating between external
representations and domain types at the boundary.

## Problem

Your application integrates with an external service whose data model you do not control. The
external API returns data in a shape that does not match your domain model: different field names,
different granularity, combined or split concepts, or entirely different structures.

If the domain adapts to the external shape, every change in the external API ripples through your
business logic. The domain becomes a mirror of someone else's data model instead of reflecting your
own business concepts.

## Pattern

Place an **Anti-Corruption Layer (ACL)** between the external system and your domain. The ACL
translates external data shapes into domain types on the way in, and domain types into external
shapes on the way out.

The domain defines what it needs through a **port interface**. The ACL sits in the infrastructure
layer, implements that port, and handles all translation.

For search operations, the port uses the **Criteria pattern**: a domain value object that
encapsulates filters, sorting, and pagination. The ACL translates domain criteria into whatever
query format the external API requires (query params, POST body, GraphQL filters, etc.).

```
┌──────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                            │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  VenueSearchCriteria (value object)                    │   │
│  │                                                       │   │
│  │  city?: String                                        │   │
│  │  min_capacity?: PositiveInteger                       │   │
│  │  country?: CountryCode                                │   │
│  │  available_on?: DateRange                             │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────┐      ┌──────────────────────────────────┐  │
│  │  BookVenue   │─────>│  VenueProvider (port)            │  │
│  │              │      │                                  │  │
│  │              │      │  search(criteria) -> [Venue]     │  │
│  │              │      │  find(id) -> Venue?              │  │
│  └──────────────┘      └───────────────┬──────────────────┘  │
│                                        │ interface            │
│  Domain types:                         │                      │
│  Venue { name, capacity, address }     │                      │
└────────────────────────────────────────┼─────────────────────┘
                                         │
┌────────────────────────────────────────┼─────────────────────┐
│              INFRASTRUCTURE LAYER      │                      │
│                                        │ implements           │
│  ┌─────────────────────────────────────▼──────────────────┐  │
│  │            ACL: TicketmasterVenueProvider                   │  │
│  │                                                        │  │
│  │  search(criteria):                                     │  │
│  │    1. Translate domain Criteria to API query:          │  │
│  │       criteria.city       -> ?city=madrid              │  │
│  │       criteria.min_cap    -> ?min_seats=500            │  │
│  │       criteria.country    -> ?country_iso=ES           │  │
│  │    2. Call external API with translated params         │  │
│  │    3. Receive external shape:                          │  │
│  │       { venue_name, max_attendees, addr_line_1,        │  │
│  │         addr_line_2, postal_code, country_iso }        │  │
│  │    4. Translate each result to domain Venue            │  │
│  │    5. Return list of domain Venues                     │  │
│  └────────────────────────┬───────────────────────────────┘  │
│                           │ calls                             │
└───────────────────────────┼───────────────────────────────────┘
                            │
                ┌───────────▼───────────────┐
                │     EXTERNAL API           │
                │                            │
                │  GET /venues               │
                │    ?city=madrid             │
                │    &min_seats=500           │
                │    &country_iso=ES          │
                │                            │
                │  Response:                 │
                │  { venue_name: "...",       │
                │    max_attendees: 500,      │
                │    addr_line_1: "...",      │
                │    addr_line_2: "...",      │
                │    postal_code: "28001",    │
                │    country_iso: "ES" }      │
                └────────────────────────────┘
```

## Why Criteria, not specific query methods

Adding `find_by_city()` to the port works for one filter. But then you need `find_by_capacity()`,
then `find_by_city_and_capacity()`, then `find_by_city_and_capacity_and_country()` — combinatorial
explosion.

The Criteria pattern solves this:

```
# BAD — combinatorial explosion in port interface
VenueProvider:
    find_by_city(city) -> [Venue]
    find_by_capacity(min) -> [Venue]
    find_by_city_and_capacity(city, min) -> [Venue]    # and growing...

# GOOD — single search method, extensible criteria
VenueProvider:
    search(criteria: VenueSearchCriteria) -> [Venue]
    find(id: VenueId) -> Venue?

VenueSearchCriteria:                      # domain value object
    city?: String
    min_capacity?: PositiveInteger
    country?: CountryCode
    available_on?: DateRange
    # adding a new filter = adding a field, NOT changing the port
```

The Criteria is a **domain value object** — it lives in the domain layer and uses domain types
(`PositiveInteger`, `CountryCode`, `DateRange`), not API query strings. The ACL translates it to
whatever the external API needs.

## When to use

- Integrating with any external service whose data model you do not control
- Consuming third-party APIs (payment providers, mapping services, CRMs)
- Integrating with legacy systems that have a different domain model
- Wrapping SDKs that expose their own type system
- Any boundary where external shapes differ from your domain concepts

## Layers involved

| Layer                      | Role                          | Contains                                                                |
| -------------------------- | ----------------------------- | ----------------------------------------------------------------------- |
| `domain/`                  | Defines what the domain needs | `VenueSearchCriteria` (value object) + `VenueProvider` (port interface) |
| `infrastructure/external/` | Implements the ACL            | `TicketmasterVenueProvider` with translation logic                      |
| `test/doubles/`            | Provides test implementation  | `InMemoryVenueProvider`                                                 |
| Composition root           | Wires the ACL to the port     | Selects which provider implementation to inject                         |

## Translation responsibilities

The ACL handles all of the following:

- **Criteria translation**: Domain `VenueSearchCriteria` to external API query params
- **Field mapping**: `venue_name` becomes `name`, `max_attendees` becomes `capacity`
- **Structure reshaping**: Flat address fields become an `Address` value object
- **Type conversion**: String dates to domain date types, string enums to domain enums
- **Default values**: Fill in domain-required fields that the external API omits
- **Error translation**: External API errors become domain-meaningful exceptions
- **Null handling**: External nulls converted to domain-appropriate representations

## Real example concept

A venue provider API returns:

```
{ venue_name, max_attendees, addr_line_1, addr_line_2, postal_code, country_iso }
```

Your domain needs:

```
Venue {
    name: String,
    capacity: PositiveInteger,
    address: Address { street, city, postal_code, country }
}
```

The ACL maps `venue_name` to `name`, `max_attendees` to a `PositiveInteger` value object, and
combines the flat address fields into a structured `Address` value object. The domain never sees the
external shape.

When searching, the ACL translates a `VenueSearchCriteria { city: "Madrid", min_capacity: 200 }`
into the external API call `GET /venues?city=madrid&min_seats=200`. The domain expresses intent; the
ACL handles the protocol.

## Common mistakes

**Letting external types leak into the domain**: If use cases receive objects typed as
`ExternalVenueResponse`, the domain is coupled to the external API. The ACL must return domain types
only.

**No ACL — domain adapts to external shapes**: The domain model mirrors the external API structure.
When the external API changes its field names or adds a wrapper object, domain logic breaks. The
translation layer is not optional.

**Hardcoding query methods instead of Criteria**: Adding `find_by_X()` for each filter creates
combinatorial explosion in the port interface. Use a Criteria value object that can be extended with
new filters without changing the port signature.

**ACL with business logic**: The ACL should only translate shapes. Validation rules ("capacity must
be positive") belong in the domain's value objects. Filtering logic ("only venues in active cities")
belongs in the use case.

**One monolithic ACL for multiple external services**: Each external service should have its own ACL
implementing its own port. A single class translating for three different APIs becomes
unmaintainable.

**Not testing the translation**: ACL translation logic is a common source of bugs (wrong field
mapping, off-by-one in type conversion). Each ACL should have unit tests that verify the translation
from external shapes to domain types, using recorded API responses as fixtures.
