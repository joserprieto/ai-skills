# Semantic Versioning

This repo uses **two parallel SemVer streams** because it ships a collection of independent
artefacts, not a single library.

## The two version streams

### 1. Repo version (`.semver`)

Tracks the state of the meta-project: tooling, conventions, scaffolding, infrastructure shared
across all skills. Bumped only when something changes at the repo level (new automation, breaking
change in conventions, restructure).

```bash
cat .semver
# 0.1.0
```

Driven by [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) and
the `make release/*` targets:

```bash
make release/dry-run     # Preview the next bump from commits
make release/patch       # Bug fix in tooling/infra
make release/minor       # New convention, new automation
make release/major       # Breaking change in repo conventions
```

### 2. Per-skill version (`metadata.version` in frontmatter)

Each skill versions independently. The version lives in its own `SKILL.md` frontmatter:

```yaml
---
name: huly-api
description: …
metadata:
  author: …
  version: '0.1.1'
---
```

Bumped manually when the skill's content changes. The bump shows up in two places:

1. The frontmatter (single source of truth for that skill's version).
2. The commit subject line, so history shows the skill's progression at a glance:

```
feat(huly-api): v0.1.0 — initial release
fix(huly-api): v0.1.1 — generalise credentials path
feat(huly-api): v0.2.0 — add token-based auth
```

## Why two streams?

A single `.semver` for the whole repo would force every skill to bump in lockstep with every
unrelated change in another skill. That makes the version meaningless: bumping `huly-api` to
`v0.5.0` because `drawio-uml-shapes` got a fix in line 437 of its docs would erode trust in the
version field.

The two streams keep each artefact's history honest. A consumer who wants only `repo-kickstart` can
pin to its own version (`0.7.1`) without caring about the rest. The repo version is secondary,
useful for tracking conventions and infra changes only.

## Bump rules per skill

Same SemVer semantics as a regular library, scoped to that skill's content:

### MAJOR (X.0.0)

The skill's behaviour or activation triggers change in a way that **breaks existing users**:

- Activation triggers removed, requiring users to update their prompts.
- Workflow steps renamed or restructured in a way that breaks downstream automation.
- Removing tooling references that consumers may rely on.

### MINOR (x.Y.0)

Backwards-compatible additions:

- New activation triggers.
- New workflow sections, examples, or references.
- New companion files in `references/`.

### PATCH (x.y.Z)

Backwards-compatible fixes:

- Typo fixes, clarifications, prose polish.
- Adding warnings about known footguns (the recent
  [drawio-uml-shapes v0.5.1](../../skills/drawio-uml-shapes/SKILL.md) is exactly this case).
- Updating examples to reflect current tool output.

## Pre-release versions

Both streams support prereleases when needed:

```yaml
metadata:
  version: '0.5.0-alpha.1'
```

Use sparingly — most skills are inherently stable text. Prereleases make sense for skills that embed
tooling whose external dependency is itself in flux (e.g., a skill targeting an unreleased SDK).

## Git tags

Tags only apply to **repo-level** releases (driven by `make release/*`), prefixed with `v`:

```
v0.1.0
v0.2.0
```

Skills are not tagged individually — their version lives in the frontmatter and the commit history
is the audit trail.

## Related

- [commits.md](./commits.md) — Commit message format (per-skill scopes carry the skill version).
- [changelog.md](./changelog.md) — CHANGELOG generation.
- [releases.md](./releases.md) — Release workflow.
- [skills-index.md](./skills-index.md) — Auto-generated index of skills with their current versions.
