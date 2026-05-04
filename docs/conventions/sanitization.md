# Sanitisation Process

When migrating a skill from a private repo (where it can mention clients, internal projects, and
personal conventions) to a public repo, it must be sanitised. The 2026-05-04 audit showed that **a
single sed pass is not enough** — context-bound names embedded in example prose ("Personal Site",
"ACOPLA setup", "ET Construction") survive automatic find-and-replace and only show up under manual
review.

This document is the canonical 2-phase procedure.

## Phase 1 — Automated token sweep

Replace known tokens with neutral equivalents. Run this first because it's cheap, mechanical, and
covers ~80% of the surface area.

### Standard token map

| Token (private)              | Replacement (public)             | Notes                                        |
| ---------------------------- | -------------------------------- | -------------------------------------------- |
| `joserprieto`                | `myorg`                          | Tenant tag in URL examples                   |
| `\bjrp\b`                    | `myorg`                          | Short-form tenant tag (must be word-bounded) |
| `JRP_`                       | `APP_`                           | Env var prefix                               |
| `joserprieto ecosystem`      | _(remove)_                       | Phrase that signals private-repo origin      |
| `/Users/joserprieto/...`     | `<your-path>`                    | Absolute home paths                          |
| `~/.ai/secrets/<file>`       | `<your-credentials-path>/<file>` | Personal secret-store paths                  |
| Author email patterns (kept) | n/a                              | Author email in frontmatter is allowed       |

### Recipe

```bash
# Apply per-token replacements, file by file, recursively in the migrated skill:
SKILL=skills/<name>

# Tenant tag in URL examples (FQDN-style, with leading dot)
find "$SKILL" -name '*.md' -exec sed -i.bak 's/\.jrp\.localhost/\.myorg\.localhost/g' {} \;

# Standalone short-form tenant tag (use word boundaries so we don't break "JRP_" elsewhere)
find "$SKILL" -name '*.md' -exec sed -i.bak 's/\b\.jrp\b/.myorg/g' {} \;

# Env var prefix
find "$SKILL" -name '*.md' -exec sed -i.bak 's/JRP_/APP_/g' {} \;

# "joserprieto ecosystem" phrase (full match, keep surrounding sentence to revise manually)
find "$SKILL" -name '*.md' -exec sed -i.bak 's/joserprieto ecosystem/<<MANUAL: rephrase>>/g' {} \;

# Personal secret store paths
find "$SKILL" -name '*.md' -exec sed -i.bak 's|~/.ai/secrets/|<your-credentials-path>/|g' {} \;

# Cleanup the .bak files
find "$SKILL" -name '*.md.bak' -delete
```

### Verification after Phase 1

```bash
grep -rnE '\bjrp\b|joserprieto|JRP_|/Users/joserprieto|\.ai/secrets' skills/<name>
```

The grep should return:

- The author email in `metadata.author` (allowed — `hi [at] joserprieto [dot] es` is the publicly
  listed contact for the maintainer).
- Nothing else.

If it returns more, repeat Phase 1 with additional tokens before moving on.

## Phase 2 — Manual prose review

Phase 1 cannot catch contextual references that don't match a fixed token. The 2026-05-04 audit
detected several of these surviving Phase 1:

| Surviving reference        | Where found           | Reason it slipped through              |
| -------------------------- | --------------------- | -------------------------------------- |
| `Personal Site`            | portless examples     | English noun phrase, no token          |
| `PS`                       | portless examples     | Abbreviation, ambiguous in isolation   |
| `ps`, `sc`, `cp-analytics` | portless examples     | Project codes, look like normal text   |
| `ACOPLA setup`             | huly-api gotchas (×5) | Project name embedded in dates         |
| `ET Construction`          | huly-api documents.md | Real client title used as example name |
| `Requisito`                | huly-api structure.md | Spanish word for a real custom field   |

### Manual review checklist

Run a single pass of grep with the patterns below. For each match, decide whether it's a legitimate
reference (e.g., "Personal Site" inside a snippet that genuinely demonstrates that naming) or a
contextual leak (the same phrase in prose explaining a generic concept).

```bash
SKILL=skills/<name>

# 1. Internal project / client names (extend this list per migration)
grep -rnE '\b(Personal Site|ACOPLA|ET Construction|Cuatro Digital|Avincis)\b' "$SKILL"

# 2. Short codes: 2-3 letter all-lowercase tokens that could be project abbreviations
#    (review every match; many will be legitimate words like "se", "no", "or")
grep -rnE '\b(ps|sc|cp-analytics)\b' "$SKILL"

# 3. Dates with personal project context ("during X setup", "from Y migration")
grep -rnE 'during [A-Z][a-z]+ ' "$SKILL"
grep -rnE '(setup|migration) of [A-Z]' "$SKILL"

# 4. Spanish words used as field/value examples (review each — many are deliberate i18n
#    but some are leaks of a Spanish-speaking client's domain language)
grep -rnE '\b(Requisito|Pendiente|Aprobado|Nombre|Estado)\b' "$SKILL"

# 5. URL examples with non-generic app names
grep -rnE 'https?://[a-z0-9-]+\.(localhost|example\.com|example\.org)/' "$SKILL"
```

For each remaining hit:

- **Replace with neutral placeholder** if the term is incidental: `Personal Site` → `Marketing Site`
  or `My App`. `ET Construction` → `Acme Corp`.
- **Replace with explicit-fictional marker** if the term is part of a worked example:
  `during ACOPLA setup` → `during real-world usage` or `during a 2025 migration`.
- **Keep** only if the term is genuinely generic and the apparent leak is incidental (e.g., "Estado"
  used as a column name in a generic Spanish UI demo).

### Recommended replacements

| Original                              | Replacement                              |
| ------------------------------------- | ---------------------------------------- |
| Personal project names                | "My App", "Sample Project", "Demo"       |
| Client names                          | "Acme Corp", "Client A"                  |
| Real-world dates with project context | "real-world usage", generic year         |
| Spanish field-value examples          | English neutral or "field-1" / "value-1" |

## Phase 3 — Author email obfuscation

This is not strictly part of the sanitisation but always runs at the same time. The author email in
`metadata.author` should be obfuscated to deter scrapers:

```yaml
metadata:
  author: Jose R. Prieto (hi [at] joserprieto [dot] es)
  #                       ^^^^      ^^^^^^^^^^^   ^^^^
  #                       This format is intentional — `[at]` and `[dot]` are
  #                       the standard documentation obfuscation.
```

Do NOT use the literal `@` or `.` in committed files for the author's email. Pre-commit hook detects
literal email patterns and blocks them as a "personal data leak" — that's the deliberate gate.

## Verification: end-to-end

After both phases, the migrated skill should pass:

```bash
# 1. Generic leak check (the same the pre-commit hook runs)
.githooks/pre-commit  # or a stand-alone equivalent

# 2. Cross-refs (Phase 1 sometimes leaves dangling references)
make lint/cross-refs

# 3. Make-target references (catches stale examples)
make lint/skill-examples

# 4. Manual final read-through
# Read the SKILL.md and every reference once with fresh eyes. Look for:
# - Anything that would only make sense to someone in your private context.
# - Tooling assumptions you didn't notice you were making.
# - Apparent generality contradicted by a single concrete example.
```

If all four pass, the migration is ready.

## Related

- [skill-ownership.md](./skill-ownership.md) — Trigger overlap and ownership rules.
- [skills-index.md](./skills-index.md) — Cross-ref validation and smoke-check tooling.
- [commits.md](./commits.md) — Commit message style for migration commits.
