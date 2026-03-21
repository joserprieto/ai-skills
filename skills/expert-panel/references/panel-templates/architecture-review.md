# Panel Template: Architecture Review

Use this template when evaluating software architecture, system design, ADRs (Architecture Decision
Records), C4 diagrams, or technical design documents.

## Suggested areas and evaluators

### Area 1: Design quality (3-5 evaluators)

| ID    | Specialisation                        | Focus                                         |
| ----- | ------------------------------------- | --------------------------------------------- |
| DES-1 | Separation of concerns and modularity | Are responsibilities clearly separated?       |
| DES-2 | API design and contracts              | Are interfaces well-defined and consistent?   |
| DES-3 | Data modelling and persistence        | Is the data model appropriate and normalised? |
| DES-4 | Error handling and resilience         | How does the system handle failures?          |
| DES-5 | Extensibility and maintainability     | Can the system evolve without major rewrites? |

### Area 2: Operational readiness (3-5 evaluators)

| ID    | Specialisation               | Focus                                     |
| ----- | ---------------------------- | ----------------------------------------- |
| OPS-1 | Scalability and performance  | Can the system handle expected load?      |
| OPS-2 | Observability and monitoring | Can operators understand system health?   |
| OPS-3 | Deployment and CI/CD         | Is the deployment pipeline well-designed? |
| OPS-4 | Disaster recovery and backup | What happens when things go wrong?        |
| OPS-5 | Cost efficiency              | Is the architecture cost-proportionate?   |

### Area 3: Security and compliance (2-4 evaluators)

| ID    | Specialisation                         | Focus                                  |
| ----- | -------------------------------------- | -------------------------------------- |
| SEC-1 | Authentication and authorisation       | Are access controls properly designed? |
| SEC-2 | Data protection and privacy            | GDPR, encryption at rest/transit?      |
| SEC-3 | Supply chain and dependency security   | Are dependencies managed and audited?  |
| SEC-4 | Compliance and regulatory requirements | Does it meet industry standards?       |

## Suggested minimum panel

For a quick review: DES-1, DES-2, OPS-1, OPS-2, SEC-1 (5 evaluators, 1 batch)

For a thorough review: All evaluators above (12-14 evaluators, 3 batches)
