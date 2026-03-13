---
name: daily-work-tracking
description: >-
  Use when the user asks to fill in daily time-tracking from AI agent sessions, generate work blocks
  for a daily tracking file, or extract what was worked on today. Converts work-extractor output
  into formatted work blocks and 3-metric summaries for the TIL daily tracking system. Triggers:
  "rellena el daily", "bloques de trabajo de hoy", "genera los bloques", "qué he trabajado hoy",
  "daily tracking", "fill daily", "extract work blocks for tracking".
metadata:
  author: Jose R. Prieto (hi [at] joserprieto [dot] es)
  version: '0.1.0'
  requires:
    - tracking-parallel-agent-work
---

# Daily Work Tracking

Converts raw work blocks extracted from AI agent JSONL logs into formatted markdown blocks and
3-metric summaries compatible with the TIL daily time-tracking system.

This skill orchestrates the pipeline:
`work-extractor CLI → context mapping → block formatting → metrics calculation`. It does NOT create
or manage the daily tracking file itself — it generates the content that the agent inserts into the
appropriate sections.

## Prerequisites

- The `tracking-parallel-agent-work` skill must be available (provides the 3-metric model and the
  `work-extractor` CLI tool).
- The `work-extractor` CLI must be installed:

  ```bash
  cd <tracking-parallel-agent-work-skill-root>/tool && make install
  ```

## Workflow

```
User asks to fill daily tracking
        ↓
1. Run work-extractor CLI for the target date
        ↓
2. Map project_path → work context using context_mapping
        ↓
3. Enrich each block: read metadata.yaml / index.md from project
        ↓
4. Convert to TIL work block markdown format
        ↓
5. Detect overlaps between blocks
        ↓
6. Calculate 3-metric summary (throughput, wall-clock, factor)
        ↓
7. Present blocks + metrics to user for review
        ↓
8. Agent inserts into daily tracking file (agent's responsibility)
```

## Step 1: Extract blocks

Run the work-extractor CLI for the target date:

```bash
work-extractor --format json extract --date YYYY-MM-DD
```

If the user does not specify a date, use today. If the user asks for a range, use `--from` and
`--to`.

Parse the JSON output. Each day contains a `blocks` array — those are the raw work blocks.

## Step 2: Map project paths to work contexts

Each block has a `project_path` (filesystem path from the JSONL `cwd` field). Map it to a work
context label using the context mapping table below.

### Context mapping table

This table maps filesystem paths to work context labels. The mapping uses **prefix matching** — the
longest matching prefix wins.

```yaml
context_mapping:
  # Avincis (job)
  '/Users/joserprieto/Projects/joserprieto/technical-insight-lab/contexts/avincis':
    context: 'job/avincis'
    label: 'Avincis'
  '/Users/joserprieto/Projects/joserprieto/encaje-ai':
    context: 'job/avincis/encaje-ai'
    label: 'Encaje AI'
  '/Users/joserprieto/Projects/joserprieto/azure-infrastructure':
    context: 'job/avincis/azure-infra'
    label: 'Azure Infrastructure'

  # Personal
  '/Users/joserprieto/Projects/joserprieto/technical-insight-lab':
    context: 'personal/til'
    label: 'TIL'
  '/Users/joserprieto/Projects/joserprieto/professional-reawakening':
    context: 'personal/professional-reawakening'
    label: 'Professional Reawakening'
  '/Users/joserprieto/Projects/joserprieto/ai-skills':
    context: 'personal/ai-skills'
    label: 'AI Skills'
  '/Users/joserprieto/Projects/joserprieto/ai-engineering-patterns':
    context: 'personal/ai-engineering-patterns'
    label: 'AI Engineering Patterns'
  '/Users/joserprieto/Projects/joserprieto/ai-diagrams-toolkit':
    context: 'personal/ai-diagrams-toolkit'
    label: 'AI Diagrams Toolkit'

  # Cuatro Digital
  '/Users/joserprieto/Projects/joserprieto/attorneys-office-digital-efficiency':
    context: 'cuatro-digital/attorneys-office'
    label: 'Attorneys Office'

  # Fallback
  '/Users/joserprieto/Projects/joserprieto':
    context: 'personal'
    label: 'Personal'
```

**Rules**:

- Sort mapping keys by length descending before matching (longest prefix first).
- If no prefix matches, use `context: "unknown"` and `label: "Unknown"` and warn the user.
- The user may ask you to add new entries — update the table in this file.

**IMPORTANT**: The more specific path MUST match before the more general one. Example:
`/Users/joserprieto/Projects/joserprieto/technical-insight-lab/contexts/avincis` must match before
`/Users/joserprieto/Projects/joserprieto/technical-insight-lab`.

## Step 3: Enrich blocks with project metadata

For each block, attempt to read context about the project:

1. Check if `metadata.yaml` exists at the project root (`project_path/metadata.yaml`). If found,
   extract `name` and `description` fields.
2. If no `metadata.yaml`, check for `index.md` or `README.md` at the project root. Extract the first
   heading as the project name.
3. If neither exists, use the `label` from the context mapping table.

For projects within the TIL (where `project_path` is the TIL root), the `cwd` alone is not enough to
identify the sub-initiative. In this case, use `user_messages_sample` from the block to infer what
was worked on. Look for context paths, file names, or initiative names in the messages.

## Step 4: Generate work block markdown

Convert each block to the TIL daily tracking format. Timestamps must be converted from UTC to the
configured timezone (default: `Europe/Madrid`).

### Block format

```markdown
#### [HH:MM-HH:MM] {description} ({duration_formatted})

- **Contexto**: {context}
- **Planificado**: [sí|no]
- **Estado**: [✅ completado|🔄 en-progreso|⏳ pendiente]
- **Actividad/Actividades**:
  - {activity line from user_messages_sample}
- **Solapamiento**: {overlap info, only if overlapping — see Step 5}
```

### Field mapping

| TIL field       | Source                                                             |
| --------------- | ------------------------------------------------------------------ |
| `HH:MM-HH:MM`   | `start_utc` / `end_utc` converted to local timezone                |
| `{description}` | From metadata.yaml `name`, or inferred from `user_messages_sample` |
| `{duration}`    | `duration_minutes` formatted as `Xh Xmin`                          |
| `{context}`     | Context mapping result (e.g., `job/avincis/encaje-ai`)             |
| `Planificado`   | Default `sí` — the agent may ask the user                          |
| `Estado`        | Default `🔄 en-progreso` — the agent may ask the user              |
| `Actividades`   | Synthesized from `user_messages_sample` — concise bullet points    |

### Duration formatting

- `67 minutes` → `1h 7min`
- `120 minutes` → `2h 0min`
- `45 minutes` → `45min` (omit hours if zero)

### Generating activity lines

Use `user_messages_sample` to produce 2-4 concise bullet points describing what was done. Do NOT
copy messages verbatim — synthesize into activity descriptions. Example:

Messages:
`["Fix the login bug that appears when...", "Can you also check the session timeout?", "Looks good, thanks"]`

Activities:

```markdown
- Fix login bug (session handling)
- Review session timeout configuration
```

## Step 5: Detect overlaps

Compare all blocks pairwise. Two blocks overlap if their time ranges intersect:

```
overlap_start = max(block_a.start, block_b.start)
overlap_end = min(block_a.end, block_b.end)
if overlap_start < overlap_end:
    overlap_minutes = (overlap_end - overlap_start) in minutes
```

When overlap is detected, add to BOTH blocks:

```markdown
- **Solapamiento**: paralelo a {other_block_description} (HH:MM-HH:MM) — ~{overlap_minutes}min
  overlap
```

## Step 6: Calculate 3-metric summary

Apply the 3-metric model from the `tracking-parallel-agent-work` skill:

### Throughput per context

Group blocks by their mapped context. Sum `duration_minutes` per context.

```markdown
- **Throughput por contexto**:
  - Avincis: Xh Xmin
    - _encaje-ai_: Xh Xmin
  - Personal: Xh Xmin
    - _ai-skills_: Xh Xmin
  - _Total throughput_: Xh Xmin
```

### Wall-clock time

Compute the union of all block time ranges (in local time). Subtract known breaks (meals, naps —
gaps longer than the configured threshold that fall in typical break times: 14:00-17:00).

```markdown
- **Tiempo reloj**: Xh Xmin (HH:MM→HH:MM, con pausas)
```

**Only show if different from total throughput** (i.e., overlaps occurred).

### Parallelism factor

```markdown
- **Factor paralelismo**: ×X.XX
```

**Only show if > ×1.0.**

### Cost summary (optional)

If pricing data is available in the work-extractor output:

```markdown
- **Coste estimado API**: $X.XX (X tokens, modelos: model-a, model-b)
```

## Step 7: Present for review

Show the generated blocks and metrics to the user BEFORE inserting them into any file. The user may:

- Adjust descriptions
- Change `Planificado` or `Estado` values
- Add or remove blocks (manual work not captured by the extractor)
- Correct context mapping

## Step 8: Insert into daily tracking (agent responsibility)

This step is NOT part of this skill. The agent that invoked this skill is responsible for:

1. Identifying or creating the daily tracking file at the correct path
   (`/control-hub/time-tracking/YYYY/wWW/MM-DD-dayname.md`)
2. Inserting the generated blocks into the appropriate period sections (Mañana, Tarde, Noche) based
   on the block timestamps
3. Filling the "Métricas del día" section with the calculated metrics

The agent should follow the TIL control-hub protocols for file creation and section management.

## Maintaining the context mapping

When the user works on a new project not in the mapping table:

1. The skill will warn: "Unknown project path: /path/to/project"
2. Ask the user what context to assign
3. Add the new entry to the mapping table in this file
4. The mapping is version-controlled with the skill

## Common mistakes

| Mistake                                      | Fix                                                            |
| -------------------------------------------- | -------------------------------------------------------------- |
| Using UTC times in the daily tracking blocks | Always convert to local timezone (Europe/Madrid)               |
| Copying `first_user_message` as description  | Synthesize from metadata.yaml + user_messages_sample           |
| Generating the full daily file               | Only generate blocks + metrics. File management is agent's job |
| Not detecting overlaps                       | Always check all block pairs. Mark BOTH overlapping blocks     |
| Hardcoding context mapping                   | Use the prefix-matching table. Ask user for unknown paths      |
| Showing wall-clock when no overlaps          | Only show if throughput ≠ wall-clock                           |
| Skipping user review                         | ALWAYS present blocks for review before insertion              |
