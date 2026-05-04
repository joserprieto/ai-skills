# Skills Index Convention

The "Available Skills" table in `README.md` is **auto-generated** from each skill's frontmatter.
Editing it by hand is wrong — it gets overwritten on the next regeneration, and CI will fail any PR
where the table is out of sync.

## How it works

A small bash script (`.github/scripts/ci/generate-skills-index.sh`) walks `skills/*/SKILL.md`, reads
the frontmatter (`name`, `metadata.version`, first sentence of `description`), builds a markdown
table, and rewrites the block between two HTML markers in `README.md`:

```markdown
<!-- BEGIN AUTO-GENERATED SKILLS TABLE - DO NOT EDIT BELOW -->

... table ...

<!-- END AUTO-GENERATED SKILLS TABLE -->
```

Everything outside those markers stays untouched.

## Adding or modifying a skill

```bash
# 1. Edit the skill (create skills/<name>/SKILL.md or modify an existing one)
$EDITOR skills/<name>/SKILL.md

# 2. If you bumped the skill version, regenerate the README table
make skills/index

# 3. Stage both files (the SKILL.md and the regenerated README.md)
git add skills/<name>/SKILL.md README.md

# 4. Commit. Pre-commit verifies the README is in sync; if it isn't, it blocks the commit
#    with the exact command to fix it.
git commit -m "feat(<name>): vX.Y.Z — short description"

# 5. Push. CI runs the same --check on every push and PR.
git push
```

## What the script extracts

- **Skill name** — from `name:` in the frontmatter. Also used to link to `skills/<name>/SKILL.md`.
- **Version** — from `metadata.version`. Shown as `0.1.0` in the version column. Falls back to `—`
  if absent.
- **Summary** — first sentence of `description`, truncated at the first period followed by a space
  and an uppercase letter. The heuristic is `\. [A-Z]`, which deliberately skips false positives
  like `.localhost`, `e.g.`, `i.e.`, etc.

The full multi-paragraph `description` from the frontmatter still drives auto-routing in agent
platforms — only the table summary is truncated for human readability.

## Make targets

```bash
make skills/index          # Regenerate the table
make skills/index/check    # Verify it's in sync (exit 1 if not)
```

## Pre-commit hook

`.githooks/pre-commit` includes a check that runs `make skills/index/check` whenever a
`skills/*/SKILL.md` is staged. If the README is stale, the hook blocks the commit and prints:

```
Checking skills index in README.md... ✗
   Run: make skills/index and commit the updated README.md
```

The hook is **verify-only**, not auto-fix. The deliberate choice: the developer keeps control of
what enters each commit. No file gets staged silently.

## CI gate

The `validate-skills` job in `.github/workflows/ci.yml` runs the same `--check` on every push and
PR. A stale README fails the job, which blocks merging. This catches the case of a developer who
pushed with `--no-verify` or whose local hook was disabled.

## Why auto-generate

The README table was hand-maintained for the first months of the project. It rotted within weeks: at
the moment the auto-index was added, the README listed only one skill while `skills/` already
contained nine. Hand-maintained indexes always lose to time. Automation removes the failure mode
entirely.

## When to skip auto-generation

There's no legitimate "skip" mode. If you're adding a fixture, a draft, or a skill that shouldn't
appear in the public table, don't put it in `skills/`. Use `docs/proposals/` or a separate path.
Anything under `skills/<name>/SKILL.md` is treated as a published skill.

## Related

- [commits.md](./commits.md) — Commit message format (per-skill scope + version in subject).
- [versioning.md](./versioning.md) — Per-skill `metadata.version` in frontmatter.
- [cicd.md](./cicd.md) — The `validate-skills` job runs both spec validation and index sync.
