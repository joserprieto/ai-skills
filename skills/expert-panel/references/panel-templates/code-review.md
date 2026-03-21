# Panel Template: Code Review

Use this template when evaluating code, pull requests, libraries, or implementation quality.

## Suggested areas and evaluators

### Area 1: Correctness and reliability (3-4 evaluators)

| ID    | Specialisation                  | Focus                                   |
| ----- | ------------------------------- | --------------------------------------- |
| COR-1 | Functional correctness          | Does the code do what it claims to do?  |
| COR-2 | Edge case and error handling    | Are edge cases and failures handled?    |
| COR-3 | Test coverage and quality       | Are tests meaningful and comprehensive? |
| COR-4 | Concurrency and race conditions | Thread safety, async correctness?       |

### Area 2: Security (2-4 evaluators)

| ID    | Specialisation                        | Focus                                |
| ----- | ------------------------------------- | ------------------------------------ |
| SEC-1 | Input validation and injection        | OWASP Top 10, injection vectors?     |
| SEC-2 | Authentication and session management | Auth flows, token handling?          |
| SEC-3 | Secrets and credential management     | Hardcoded secrets, env var exposure? |
| SEC-4 | Dependency vulnerabilities            | Known CVEs in dependencies?          |

### Area 3: Maintainability (2-4 evaluators)

| ID    | Specialisation                  | Focus                                      |
| ----- | ------------------------------- | ------------------------------------------ |
| MNT-1 | Code clarity and naming         | Is the code readable and self-documenting? |
| MNT-2 | Architecture and patterns       | Are design patterns used appropriately?    |
| MNT-3 | Performance and efficiency      | Are there obvious performance issues?      |
| MNT-4 | Documentation and API contracts | Is the public API well-documented?         |

## Suggested minimum panel

For a quick review: COR-1, COR-2, SEC-1, MNT-1, MNT-2 (5 evaluators, 1 batch)

For a thorough review: All evaluators above (10-12 evaluators, 2-3 batches)
