# Skill Ownership and Trigger Disambiguation

When two or more skills could plausibly activate on the same input, **one of them must own that
intent and the others must defer**. This document is the matrix of those ownership rules for the
skills in this repo and the well-known external skills they overlap with.

## Why this matters

The agentskills.io `description` field is a free-text trigger. Multiple skills with overlapping
descriptions all match. The runtime then has to choose, and "choose" usually means "load the shorter
description first" or "load all and overflow context". Both outcomes are bad: one hides relevant
guidance, the other dilutes it.

The fix is documented ownership: one skill claims the trigger, the others mention the trigger **only
to defer**. That way every skill remains internally honest about what it does, and the runtime has a
clear winner.

## Conflicts identified in the 2026-05-04 audit

### 1. Architecture skills

| Trigger phrase                                        | Owner                                   | Defers (and why)                                                                                                |
| ----------------------------------------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| "contract-first", "ports and adapters", "schema SSOT" | `contract-first-clean-arch`             | `agent-skills:api-and-interface-design` (Anthropic) is general API design; this skill is the opinionated method |
| "API contract", "interface design"                    | `agent-skills:api-and-interface-design` | `contract-first-clean-arch` defers — it assumes a contract exists and tells you how to layer code under it      |
| "specification", "requirements first"                 | `agent-skills:spec-driven-development`  | `contract-first-clean-arch` defers when scope is "what should it do" rather than "how to layer the code"        |

**Action for `contract-first-clean-arch`**: trim its description triggers. The 13+ keywords include
several ("clean architecture", "bounded contexts", "architecture evaluation", "hexagonal
architecture") that are too generic and overlap with the two Anthropic skills above. Remove the
generic ones; keep the precise ones (`contract-first`, `composition root`, `criteria pattern`,
`screaming architecture`).

### 2. Service-orchestration skills

| Trigger phrase                                        | Owner                          | Defers (and why)                                                                          |
| ----------------------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------- |
| "make start/stop"                                     | `makefile-service-conventions` | naming conventions are ubiquitous, lifecycle implementation is local                      |
| "PID tracking", "log rotation", "background services" | `service-manager`              | implementation skill — the Make targets it provides follow `makefile-service-conventions` |
| "stable .localhost URL", "portless"                   | `portless-service-integration` | independent: it integrates with both of the above but can also be used alone              |

**Action for `service-manager`**: the description should explicitly say "follows
`makefile-service-conventions`" — not just imply it. Mention `portless` as an optional upstream URL
provider.

**Action for `makefile-service-conventions`**: the description should mention "for full PID tracking
and log rotation, use `service-manager` together with this".

### 3. Skill-authoring skills

| Trigger phrase                                | Owner                                         | Defers (and why)                                                        |
| --------------------------------------------- | --------------------------------------------- | ----------------------------------------------------------------------- |
| "validate skill", "lint skill", "audit skill" | `validating-skills`                           | spec-compliance check                                                   |
| "create new skill", "design skill"            | `agent-skills:using-agent-skills` (Anthropic) | navigates the skill catalogue; suggests which one to use                |
| "review skill"                                | unresolved — see note                         | `validating-skills` does spec compliance only; not architectural review |

**Note on "review skill"**: this trigger currently has no clean owner. `validating-skills` only does
mechanical spec compliance (R1-R9 rules). Architectural / structural review of a skill (does it have
the right shape, sensible references, accurate triggers) is what the 2026-05-04 audit did, but no
skill encodes that procedure. Future work: either extend `validating-skills` with a "review" mode,
or create a separate `reviewing-skills` skill.

## Pattern: how to declare a deferral

When skill A defers to skill B for a trigger, A's body should include a short note:

```markdown
## When NOT to use this skill

- For X, use the `B` skill — it owns that intent.
- …
```

This is a guard. It does not stop A from loading on that trigger (the runtime decides), but it gives
the agent that loaded A enough information to disambiguate quickly. The agent can decide "I should
be using B, let me load that and stop reading A".

## Pattern: how to claim a trigger uniquely

When a skill needs to be the unique owner of a trigger phrase, the description should:

1. Include the exact phrase verbatim — agentic platforms match strings.
2. Avoid the generic version of the phrase. "Contract-first clean architecture" is precise; "clean
   architecture" is not — that one belongs to whoever explains the term.
3. Include disambiguating context: "when **building**" vs "when **reviewing**", or "when the project
   is **new**" vs "when **existing**".

## Verifying ownership

There is no automated check for trigger overlap (yet). The manual procedure:

1. List the descriptions of all skills in scope
   (`for d in skills/*/; do grep -A3 description: "$d/SKILL.md" | head -10; done`).
2. Look for shared keywords and phrases.
3. Decide ownership per phrase using this document as reference.
4. Update descriptions and "When NOT to use" sections accordingly.

A future automation could parse all descriptions, build a token-frequency table, and flag n-grams
shared by 2+ skills. Out of scope for v1.

## Related

- [skills-index.md](./skills-index.md) — Auto-generated catalogue of skills with their current
  descriptions and versions.
- [versioning.md](./versioning.md) — When a trigger change in a description warrants a version bump.
