---
name: tracking-parallel-agent-work
description: >-
  Use when tracking work time and the user runs concurrent AI agent sessions, has overlapping time
  blocks, or works on multiple projects simultaneously in separate terminals. Also use when asked to
  produce daily work summaries, weekly capacity reports, or project-level time breakdowns where
  parallel sessions may inflate totals. Triggers: "time tracking", "daily summary", "hours per
  project", "weekly capacity", "parallel sessions", "concurrent agents", "overlapping blocks".
metadata:
  author: Jose R. Prieto (hi [at] joserprieto [dot] es)
  version: '0.2.0'
---

# Tracking Parallel Agent Work

Model for tracking work time when AI agents run concurrent sessions, producing more output than
wall-clock time allows serially. Includes the `work-extractor` CLI tool for automated block
extraction from Claude Code JSONL logs.

## Overview

When a user runs multiple AI agent sessions in parallel (separate terminals, concurrent tasks), time
blocks overlap. Naively summing all blocks inflates the total beyond the hours actually spent
working. This skill defines a 3-metric model that separates what each project received (throughput)
from how long the user was actually at the desk (wall clock).

**Core principle**: AI agents expand your **productivity**, not your **capacity**. Your body is
still in the chair for wall-clock hours. Track both, use each for its purpose, never mix them.

## The 3-Metric Model

| Metric                     | Priority  | What it measures                   | Use for                                            |
| -------------------------- | --------- | ---------------------------------- | -------------------------------------------------- |
| **Throughput per context** | PRIMARY   | Hours each project/client received | Project tracking, billing, per-context weekly sums |
| **Wall-clock time**        | SECONDARY | Real elapsed time at the desk      | Wellness, weekly capacity (e.g. 45h/week), fatigue |
| **Parallelism factor**     | DERIVED   | Throughput total / wall-clock time | Productivity KPI over time                         |

### Calculation rules

**Throughput per context**:

```
Throughput(context) = sum of duration of each block in that context
```

Each context gets its FULL block duration, even if it overlaps with another context. This is
correct: both contexts received that work.

**Wall-clock time**:

```
Wall-clock = last_block_end - first_block_start - known_gaps
Known gaps = meals, breaks, naps (non-work periods between blocks)
```

Alternatively, compute the union of all time ranges and sum the covered intervals.

**Parallelism factor**:

```
Factor = total_throughput / wall_clock
If factor <= 1.0: omit (no parallelism occurred)
If factor > 1.0: show as multiplier (e.g., x1.16)
```

## Quick Reference

### When to show what

| Situation                        | Show throughput          | Show wall-clock               | Show factor |
| -------------------------------- | ------------------------ | ----------------------------- | ----------- |
| No overlapping blocks            | Yes (= wall-clock)       | No (redundant)                | No          |
| Some overlapping blocks          | Yes                      | Yes                           | Yes         |
| Producing weekly capacity report | Per-context throughput   | Total wall-clock for capacity | Optional    |
| Billing a client                 | That client's throughput | No                            | No          |

### Marking overlaps in work blocks

When two blocks ran concurrently, add to BOTH blocks:

```markdown
- **Overlap**: parallel to [task name] (HH:MM-HH:MM) — ~Xmin overlap
```

The overlap duration is the intersection of the two time ranges.

## Critical Rules

### Capacity planning uses wall-clock, NEVER throughput

A user with 45h/week capacity who works 13h wall-clock on Monday has 32h left for the week — not
`45 - throughput`. The parallelism factor expands output, not available hours.

```
WRONG:  remaining = 45h - 15h39m throughput = 29h21m
RIGHT:  remaining = 45h - 13h28m wall-clock = 31h32m
```

### Throughput per context is the primary display metric

When showing daily/weekly summaries, lead with throughput per context. This is what the user and
stakeholders care about: how much did each project receive?

Wall-clock is secondary context (for wellness/planning). Factor is a derived KPI.

### No parallelism? No extra metrics

If a day has zero overlapping blocks, throughput equals wall-clock. Show only throughput (the
simpler model). Do not add wall-clock or factor — they add noise with no signal.

## Daily Summary Template

```markdown
### Metrics

- **Throughput per context**:
  - Client A: Xh Xmin
    - project-1: Xh Xmin
  - Personal: Xh Xmin
    - project-2: Xh Xmin
  - _Total throughput_: Xh Xmin
- **Wall-clock time**: Xh Xmin (HH:MM to HH:MM, with breaks)
- **Parallelism factor**: xN.NN
```

Omit wall-clock and factor lines if no overlaps occurred.

## Weekly Summary Template

```markdown
### Week Summary

| Context      | Mon   | Tue   | Wed   | Thu   | Fri   | Total |
| ------------ | ----- | ----- | ----- | ----- | ----- | ----- |
| Client A     | 3h    | 4h    | 2h    | 5h    | 3h    | 17h   |
| Personal     | 5h    | 3h    | 4h    | 2h    | 6h    | 20h   |
| _Throughput_ | 8h    | 7h    | 6h    | 7h    | 9h    | 37h   |
| _Wall-clock_ | 7h    | 7h    | 6h    | 6h    | 8h    | 34h   |
| _Factor_     | x1.14 | x1.00 | x1.00 | x1.17 | x1.13 | x1.09 |
```

Wall-clock row is what counts against weekly capacity. Throughput row is what each project received
in total.

## Worked Example

Five work blocks, some overlapping:

```
[09:00-11:30] Project Alpha — backend    (2h 30min)
[10:15-12:45] Project Beta  — migration  (2h 30min)  ← overlaps A
[14:00-16:00] Project Alpha — frontend   (2h 00min)
[15:30-17:30] Project Gamma — CI/CD      (2h 00min)  ← overlaps C
[20:00-22:00] Project Beta  — testing    (2h 00min)
```

**Throughput per context**:

- Alpha: 2h30 + 2h00 = **4h 30min**
- Beta: 2h30 + 2h00 = **4h 30min**
- Gamma: **2h 00min**
- _Total throughput_: **11h 00min**

**Wall-clock**: Union of ranges = 09:00-12:45 + 14:00-17:30 + 20:00-22:00 = 3h45 + 3h30 + 2h00 =
**9h 15min**

**Factor**: 11h00 / 9h15 = **x1.19**

**Overlaps to mark**:

- Block A: "parallel to Beta migration (10:15-11:30) — ~1h15 overlap"
- Block B: "parallel to Alpha backend (10:15-11:30) — ~1h15 overlap"
- Block C: "parallel to Gamma CI/CD (15:30-16:00) — ~30min overlap"
- Block D: "parallel to Alpha frontend (15:30-16:00) — ~30min overlap"

## Common Mistakes

| Mistake                                    | Fix                                                                        |
| ------------------------------------------ | -------------------------------------------------------------------------- |
| Summing all blocks as "total hours worked" | That is throughput, not wall-clock. Show both if overlaps exist.           |
| Using throughput for capacity planning     | Capacity = wall-clock. Your week has 45h of clock, not 45h of throughput.  |
| Showing wall-clock/factor when no overlaps | Omit — adds noise. Only show when parallelism actually occurred.           |
| Marking overlap on only one block          | Mark BOTH overlapping blocks.                                              |
| Reporting factor < x1.0                    | Factor < 1.0 means gaps between blocks. Omit factor; it is not meaningful. |
| Averaging factor across weeks              | Factor is per-day or per-week. Cross-week averages hide daily patterns.    |

---

## Automated Extraction: work-extractor CLI

The `work-extractor` tool extracts work blocks from Claude Code JSONL session logs automatically. It
lives alongside this skill at `tool/` and produces structured output (YAML or JSON) that can be
consumed by downstream skills or scripts.

### Installation

```bash
cd <skill-root>/tool
make install   # or: uv sync
```

### CLI usage

```bash
# Extract today's blocks
work-extractor extract

# Extract a specific date
work-extractor extract --date 2026-03-12

# Extract a date range
work-extractor extract --from 2026-03-10 --to 2026-03-12

# JSON output
work-extractor --format json extract --date 2026-03-12

# Custom config file
work-extractor --config /path/to/config.yaml extract

# List sessions for a date
work-extractor sessions --date 2026-03-12
```

### Global options (before subcommand)

| Flag            | Default                                               | Description                           |
| --------------- | ----------------------------------------------------- | ------------------------------------- |
| `--config`      | bundled `config.yaml`                                 | Path to custom config file            |
| `--search-path` | `~/.ai/claude-code/accounts/*/profiles/*/projects/*/` | Glob pattern for JSONL files          |
| `--timezone`    | `Europe/Madrid`                                       | Timezone for date grouping            |
| `--gap`         | `30`                                                  | Minutes of inactivity to split blocks |
| `--format`      | `yaml`                                                | Output format: `yaml` or `json`       |

### Output schema

Each extraction produces a list of day summaries. Each day contains work blocks:

```yaml
- date: '2026-03-12'
  timezone: 'Europe/Madrid'
  total_blocks: 5
  total_duration_minutes: 420
  total_tokens:
    input: 12340
    output: 45600
    cache_creation: 8900
    cache_read: 1234000
  total_tokens_combined: 1300840
  models_used: ['claude-opus-4-6', 'claude-sonnet-4-6']
  accounts_used: ['joserprieto-me']
  estimated_cost_usd: 1.234567
  projects:
    - path: '/Users/jose/Projects/my-app'
      duration_minutes: 240
  blocks:
    - session_id: 'abc123...'
      project_path: '/Users/jose/Projects/my-app'
      account: 'joserprieto-me'
      profile: 'standard'
      start_utc: '2026-03-12T08:21:00Z'
      end_utc: '2026-03-12T10:08:00Z'
      duration_minutes: 107
      first_user_message: 'Fix the login bug...'
      model: 'claude-opus-4-6'
      tools_used: { 'Edit': 12, 'Read': 8, 'Bash': 5 }
      message_count: { 'user': 15, 'assistant': 14 }
      token_usage:
        input: 2340
        output: 8900
        cache_creation: 1200
        cache_read: 245000
      total_tokens: 257440
      user_messages_sample:
        - 'Fix the login bug that...'
        - 'Can you also check...'
        - 'Looks good, thanks'
      estimated_cost_usd: 0.234567
```

### Key fields for downstream consumers

| Field                   | Purpose                                                          |
| ----------------------- | ---------------------------------------------------------------- |
| `project_path`          | Filesystem path — map to your context system                     |
| `start_utc` / `end_utc` | UTC timestamps — convert to local for display                    |
| `duration_minutes`      | Block duration (throughput per block)                            |
| `first_user_message`    | Quick description of what the block was about                    |
| `user_messages_sample`  | Sampled user messages for semantic context (see DD-005)          |
| `model`                 | Primary model used in the block                                  |
| `token_usage`           | 4-category breakdown (input, output, cache_creation, cache_read) |
| `estimated_cost_usd`    | Cost estimate based on configured pricing (null if no pricing)   |

### Configuration (config.yaml)

All parameters are configurable via `config.yaml`. A bundled default ships with the package. Key
sections:

- **sampling**: Controls how many user messages are captured per block (first N + last N + uniform
  middle). See `tool/docs/design-decisions.md` DD-005 for rationale.
- **pricing**: USD per 1M tokens per model. Includes `cache_write` and `cache_read` rates. Source:
  Anthropic pricing page.

### From blocks to 3-metric model

The work-extractor outputs raw blocks. To compute the 3-metric model:

1. **Throughput per context**: Group blocks by `project_path`, sum `duration_minutes` per group.
2. **Wall-clock time**: Compute the union of all `[start_utc, end_utc]` intervals for the day,
   subtract known breaks. This is NOT the sum of durations — it is the total time span covered.
3. **Parallelism factor**: `total_throughput / wall_clock`. Only show if > 1.0.
4. **Overlap detection**: For each pair of blocks, check if their time ranges intersect. If so, mark
   both blocks with the overlap duration and the other block's description.

The tool does NOT compute these metrics — it provides the raw data. The consuming skill or agent
applies the 3-metric model using the rules defined in this skill.

### Design decisions

See `tool/docs/design-decisions.md` for rationale on:

- DD-001: Project path extraction from `cwd` field
- DD-002: Gap-based block splitting (30-min default)
- DD-003: Cache token tracking (95%+ of input tokens are cache reads)
- DD-004: External pricing configuration
- DD-005: Message sampling strategy (three-zone: first N + last N + uniform middle)
- DD-006: Only user messages, not assistant messages
