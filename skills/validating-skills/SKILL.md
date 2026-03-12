---
name: validating-skills
description: >-
  Use when validating, auditing, or reviewing Agent Skills for compliance with the agentskills.io
  specification. Also use when creating new skills to verify format requirements, when asked to
  "validate skill", "check skill", "audit skill", "lint skill", or "review skill compliance".
metadata:
  author: Jose R. Prieto (hi [at] joserprieto [dot] es)
  version: '0.1.0'
---

# Validating Agent Skills

Validates Agent Skills against the
[Agent Skills specification](https://github.com/agentskills/agentskills).

## Validation procedure

1. Read the target skill's `SKILL.md` and list all files in the skill directory
2. Walk through each rule section below
3. Record a verdict per rule (see severity levels)
4. Report findings in the output format at the end

## Severity levels

| Level    | Meaning                                   | Action      |
| -------- | ----------------------------------------- | ----------- |
| **FAIL** | Violates a spec requirement               | Must fix    |
| **WARN** | Violates a best-practice recommendation   | Should fix  |
| **PASS** | Compliant                                 | No action   |
| **SKIP** | Rule not applicable (e.g., no `scripts/`) | Note as N/A |

**Default severity by section:**

- R1 (name), R2.1–R2.3 (description constraints), R4.1–R4.2 (structure) → **FAIL** if violated
- Everything else → **WARN** if violated
- Sections about optional content (R3, R7) → **SKIP** if the feature is absent

## R1: Frontmatter — `name` field

Required. The primary identifier for the skill.

| Rule | Criteria                                                                   |
| ---- | -------------------------------------------------------------------------- |
| R1.1 | Field exists and is non-empty                                              |
| R1.2 | 1–64 characters long                                                       |
| R1.3 | Contains only lowercase letters (`a-z`), digits (`0-9`), and hyphens (`-`) |
| R1.4 | Does not start or end with a hyphen                                        |
| R1.5 | No consecutive hyphens (`--`)                                              |
| R1.6 | Matches the parent directory name exactly                                  |
| R1.7 | Does not contain reserved words: `anthropic`, `claude`                     |

**How to check R1.6:** `basename "$(dirname /path/to/SKILL.md)"`

## R2: Frontmatter — `description` field

Required. The agent reads this to decide whether to activate the skill.

| Rule | Criteria                                                                       |
| ---- | ------------------------------------------------------------------------------ |
| R2.1 | Field exists and is non-empty                                                  |
| R2.2 | 1–1024 characters long                                                         |
| R2.3 | Does not contain XML tags (`<tag>`, `</tag>`)                                  |
| R2.4 | Written in third person — no `"I can"`, `"you can"`, `"we provide"` as subject |
| R2.5 | Describes **what** the skill does                                              |
| R2.6 | Describes **when** to use the skill (triggers, contexts, symptoms)             |
| R2.7 | Includes specific keywords that help agents match tasks to this skill          |
| R2.8 | Does not summarize the skill's internal workflow or process steps              |
| R2.9 | Avoids vague terms: `"helps with"`, `"processes data"`, `"does stuff"`         |

**Why R2.8 matters:** When a description summarizes workflow, agents may follow the description
shortcut instead of reading the full SKILL.md body. Keep the description focused on triggering
conditions only.

## R3: Frontmatter — optional fields

Skip this section if no optional fields are present.

| Rule | Criteria                                                                                                         |
| ---- | ---------------------------------------------------------------------------------------------------------------- |
| R3.1 | `license`: if present, short string (license name or filename)                                                   |
| R3.2 | `compatibility`: if present, 1–500 characters                                                                    |
| R3.3 | `metadata`: if present, keys and values are both strings                                                         |
| R3.4 | `allowed-tools`: if present, space-delimited tool list                                                           |
| R3.5 | No unknown top-level keys beyond: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` |

## R4: Directory structure

| Rule | Criteria                                                                           |
| ---- | ---------------------------------------------------------------------------------- |
| R4.1 | `SKILL.md` exists at the skill root directory                                      |
| R4.2 | Skill directory name matches the `name` frontmatter field                          |
| R4.3 | Supplementary directories use standard names: `scripts/`, `references/`, `assets/` |
| R4.4 | File references from SKILL.md are one level deep (no A → B → C chains)             |
| R4.5 | All file paths use forward slashes (no backslashes)                                |
| R4.6 | File names are descriptive (not `doc1.md`, `file2.md`, `data.txt`)                 |

## R5: Content — size and structure

| Rule | Criteria                                                                                              |
| ---- | ----------------------------------------------------------------------------------------------------- |
| R5.1 | SKILL.md body (after frontmatter closing `---`) is **≤ 500 lines**                                    |
| R5.2 | Progressive disclosure: SKILL.md is an overview; heavy details are in separate files                  |
| R5.3 | Supplementary files longer than 100 lines include a table of contents at the top                      |
| R5.4 | Cross-references from SKILL.md point to files one level deep, not to files that reference other files |

**How to check R5.1:**

```bash
total=$(wc -l < SKILL.md)
frontmatter_end=$(awk '/^---$/{n++; if(n==2){print NR; exit}}' SKILL.md)
body_lines=$((total - frontmatter_end))
echo "Body lines: $body_lines (max 500)"
```

## R6: Content — quality

| Rule | Criteria                                                                                                        |
| ---- | --------------------------------------------------------------------------------------------------------------- |
| R6.1 | Concise: does not explain concepts an agent already knows                                                       |
| R6.2 | No time-sensitive information (specific dates, version countdowns, "before August 2025")                        |
| R6.3 | Consistent terminology — one term per concept throughout all files                                              |
| R6.4 | Examples are concrete with real input/output, not abstract placeholders                                         |
| R6.5 | Degree of freedom matches task fragility: strict scripts for fragile ops, flexible guidance for heuristic tasks |
| R6.6 | No multiple competing approaches offered without a clear default recommendation                                 |

**Test for R6.1:** For each paragraph, ask: "Would removing this change agent behavior?" If no,
remove it.

## R7: Scripts (if `scripts/` present)

Skip this section if the skill has no scripts.

| Rule | Criteria                                                                                    |
| ---- | ------------------------------------------------------------------------------------------- |
| R7.1 | Scripts handle errors explicitly (do not punt to the agent)                                 |
| R7.2 | No magic numbers — all constants are documented with rationale                              |
| R7.3 | Required packages and dependencies listed in SKILL.md                                       |
| R7.4 | SKILL.md clearly states whether each script should be **executed** or **read as reference** |
| R7.5 | Scripts are self-contained or clearly document their dependencies                           |

## R8: Naming conventions

| Rule | Criteria                                                            |
| ---- | ------------------------------------------------------------------- |
| R8.1 | Skill name uses gerund form (preferred) or noun phrase (acceptable) |
| R8.2 | Name is not vague: avoid `helper`, `utils`, `tools`, `misc`         |
| R8.3 | Name clearly indicates the skill's domain or action at a glance     |

**Preferred (gerund):** `processing-pdfs`, `validating-skills`, `analyzing-data`

**Acceptable (noun phrase):** `pdf-processing`, `skill-validation`, `data-analysis`

## R9: Description effectiveness

These rules evaluate whether the description enables reliable skill discovery.

| Rule | Criteria                                                                                   |
| ---- | ------------------------------------------------------------------------------------------ |
| R9.1 | An agent could select this skill from 100+ available skills based on the description alone |
| R9.2 | Description includes the primary task verbs (`extract`, `validate`, `generate`, etc.)      |
| R9.3 | Description includes domain nouns (`PDF`, `UML`, `database`, etc.)                         |
| R9.4 | Description mentions alternative phrasings a user might use                                |

## Output format

Report findings as:

```markdown
# Skill Validation Report: {skill-name}

## Summary

- **Rules evaluated:** {N}
- **PASS:** {N} | **FAIL:** {N} | **WARN:** {N} | **SKIP:** {N}
- **Verdict:** COMPLIANT / NON-COMPLIANT

A skill is NON-COMPLIANT if any rule has status FAIL.

## Findings

| Rule | Status | Detail                          |
| ---- | ------ | ------------------------------- |
| R1.1 | PASS   | name field exists: "skill-name" |
| R5.1 | FAIL   | Body is 658 lines (max 500)     |
| R7.x | SKIP   | No scripts/ directory           |
| ...  | ...    | ...                             |

## Required fixes

1. **R5.1** — Reduce SKILL.md body from 658 to ≤ 500 lines. Move [specific content] to a reference
   file.

## Recommended improvements

1. **R8.1** — Consider renaming from noun phrase to gerund form.
```

## Validation tips

- Count body lines **after** the closing `---` of YAML frontmatter, not the entire file
- For R2.3, search the raw YAML for `<` followed by a letter (exclude markdown code blocks)
- For R2.4, check the parsed description text (after YAML folding) for first/second person subjects
- For R6.1, Claude is already smart — only include information it cannot infer from context
- For R9.1, imagine reading 100 skill descriptions in a list — would this one stand out for the
  right tasks and stay invisible for the wrong ones?
- When multiple skills in the same collection are validated, check for terminology consistency
  across skills (R6.3 at the collection level)
