# Testing

Testing is **MANDATORY** in this project. TDD (Test-Driven Development) is the minimum required
approach for all new code.

## TDD Cycle (MANDATORY)

Every feature or bug fix MUST follow the Red-Green-Refactor cycle:

### 1. RED — Write a Failing Test

```bash
# Write the test FIRST
# Run it — it MUST fail
make test
# Expected: FAIL
```

The failing test defines the expected behavior. If it passes without implementation, either the
test is wrong or the feature already exists.

### 2. GREEN — Write Minimal Code to Pass

Write the **minimum** code needed to make the test pass. No more.

```bash
make test
# Expected: PASS
```

### 3. REFACTOR — Improve Without Changing Behavior

Clean up the implementation while keeping all tests green:

- Remove duplication
- Improve naming
- Simplify logic

```bash
make test
# Expected: PASS (all tests still green)
```

### 4. COMMIT

Each TDD cycle produces a meaningful commit:

```bash
git add .
git commit -m "feat(scope): add specific behavior"
```

## Test Structure

Organize tests by type:

```
tests/
├── unit/           # Fast, isolated, no external dependencies
├── integration/    # Test component interactions
├── acceptance/     # Business requirement verification
└── e2e/            # End-to-end (optional, expensive)
```

### Test Pyramid

Aim for this distribution:

```
        /  e2e  \          Few, slow, expensive
       / accept. \
      / integration\
     /    unit      \      Many, fast, cheap
```

- **Unit tests**: Most tests should be here. Fast, isolated, no I/O.
- **Integration tests**: Test boundaries between components.
- **Acceptance tests**: Verify business requirements are met.
- **E2E tests**: Only for critical user journeys.

## Naming Convention

Test names should describe the behavior, not the implementation:

```
# Good
test_returns_empty_list_when_no_items_exist
test_raises_error_for_invalid_email_format
test_calculates_total_with_discount_applied

# Bad
test_get_items
test_validate
test_calculate
```

## What to Test

### ALWAYS test

- Business logic and domain rules
- Edge cases (empty input, boundaries, null)
- Error conditions and error messages
- Public API contracts

### NEVER test

- Framework internals
- Private methods directly
- Third-party library behavior
- Trivial getters/setters

## Extending Testing

This document defines the minimum (TDD). Projects can extend with:

- **Property-based testing**: Generate random inputs to find edge cases
- **Mutation testing**: Verify test quality by introducing deliberate bugs
- **Contract testing**: Validate API contracts between services
- **Performance testing**: Benchmark critical paths
- **Security testing**: SAST/DAST scanning

Add project-specific testing conventions below this section as the project evolves.

## Related

- [dev-workflow.md](./dev-workflow.md) - Development workflow
- [commits.md](./commits.md) - Commit message format
