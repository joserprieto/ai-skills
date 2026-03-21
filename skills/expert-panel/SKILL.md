---
name: expert-panel
description: >-
  Evaluate any artifact (document, architecture, infrastructure design, domain model, code, PR,
  proposal) using an independent panel of LLM agent evaluators. Each evaluator runs as a separate
  agent with its own context — no cross-contamination between evaluators. Produces individual
  evaluation reports + a consolidated panel report. Use when the user says "expert panel", "panel de
  expertos", "evaluate with experts", "multi-agent evaluation", "jury evaluation", "independent
  review panel", "evaluate this report/design/architecture", or when objective, multi-perspective
  evaluation of any artifact is needed. Also use when the user wants to assess vendor deliverables,
  review proposals, or validate technical decisions with simulated expert input.
license: MIT
metadata:
  author: Jose R. Prieto
  version: '0.1.0'
---

# Expert Panel Evaluation

Orchestrate N independent LLM agents as specialist evaluators to produce robust, bias-reduced
assessments of any artifact. Each evaluator runs in complete isolation (separate agent, separate
context window) to prevent opinion contamination.

## Core principle

**1 agent = 1 evaluator = 1 context window.** Asking a single agent to role-play multiple experts
produces artificial consensus, not independent evaluation. The academic literature confirms this:
independent panels with diverse evaluators outperform single-judge approaches by reducing
intra-model bias and improving alignment with human judgement (Verga et al., 2024 — PoLL; Chan et
al., 2023 — ChatEval).

## When to use

- Evaluating deliverables from external vendors or contractors
- Reviewing architecture decisions, RFCs, or technical proposals
- Assessing security reports, incident response reports, audit findings
- Validating domain models, infrastructure designs, or data schemas
- Code review with multiple specialist perspectives
- Any situation where a single reviewer's bias would be problematic

## Workflow overview

```
1. SETUP        → Gather inputs, configure panel, create manifest
2. EVALUATE     → Launch evaluators in parallel batches (1 agent each)
3. VERIFY       → Quality-check each evaluation against DoD
4. CONSOLIDATE  → Aggregate scores, consensus, dissent into panel report
5. (Optional) DEBATE → Only if explicitly requested by user
```

---

## Phase 0: Setup

### Step 1 — Identify the artifact

Ask the user:

- **What** is being evaluated? (document, architecture, design, code, proposal, etc.)
- **Where** is it? (file path or paths)
- **Why** is it being evaluated? (quality check, vendor assessment, decision support, etc.)

### Step 2 — Gather context material

Ask if there is additional context the evaluators should read:

- Related documents, prior analyses, meeting notes
- Internal standards or requirements the artifact should meet
- Known issues or concerns to pay special attention to

### Step 3 — Configure the panel

Suggest a default panel composition based on the artifact type. Read the appropriate template from
`references/panel-templates/` for suggestions. The user can accept the default, modify it, or
provide their own.

Each evaluator must have:

- **ID**: Short identifier (e.g., `SEC-1`, `ARCH-3`, `QA-2`)
- **Area**: Knowledge domain (e.g., "Security", "Architecture", "Quality Assurance")
- **Specialisation**: Specific focus within the area (e.g., "Container security and Docker
  hardening")

Recommend **3-5 evaluators per area** and **2-4 areas** for most evaluations. More evaluators add
diminishing returns; fewer than 3 per area reduce the chance of meaningful dissent.

### Step 4 — Define evaluation criteria (rubric)

Suggest a default rubric from `references/rubric-templates/`. The user can accept, modify, or
replace it.

A rubric is a scoring matrix that defines:

- **What** is scored (criteria: accuracy, completeness, clarity, etc.)
- **How** it is scored (numeric scale, e.g., 1-10)
- **What each score means** (anchors: 1-2 = deficient, 9-10 = excellent)

Without a rubric, evaluators invent their own scales and scores are not comparable.

### Step 5 — Set execution parameters

| Parameter        | Default           | Description                                                   |
| ---------------- | ----------------- | ------------------------------------------------------------- |
| `batch_size`     | 5                 | Max evaluators running in parallel                            |
| `model`          | sonnet            | Model for evaluators (cost-efficient, not orchestrator model) |
| `output_dir`     | `./expert-panel/` | Where to write evaluation outputs                             |
| `language`       | Same as artifact  | Language for evaluation reports                               |
| `execution_mode` | `agent`           | How to launch evaluators: `agent` or `team` (see below)       |

#### Execution modes

Ask the user which mode to use:

- **`agent`** (default): Use the **Agent tool** to spawn each evaluator as an independent subagent
  within the current session. Simpler setup, evaluators run as background tasks. Best for panels of
  up to ~10 evaluators. All evaluators share the same API billing context.

- **`team`** (advanced): Use **TeamCreate** to spawn each evaluator as a separate team member. Each
  team member gets its own independent session with full isolation. Better for large panels (10+
  evaluators), long-running evaluations, or when evaluators need extended context. Team members can
  be addressed individually via SendMessage if follow-up is needed.

Both modes guarantee the core principle: 1 evaluator = 1 isolated context. The difference is in
lifecycle management and scalability.

Do NOT use `claude -p` via Bash — it does not provide isolated context, writes to stdout, and may
use unsupported CLI flags.

### Step 6 — Create the evaluation manifest

Create `<output_dir>/evaluation-manifest.md` with the full evaluation specification. This file is
the **source of truth** for the evaluation and enables resumability.

```markdown
# Evaluation Manifest

## Metadata

- **ID**: eval-YYYY-MM-DD-short-description
- **Created**: YYYY-MM-DDTHH:MM:SSZ
- **Status**: in_progress | completed

## Artifact

- **Type**: document | architecture | infrastructure | domain-model | code | proposal
- **Description**: [what is being evaluated and why]
- **Files**:
  - `path/to/artifact`
- **Context files**:
  - `path/to/context-1`
  - `path/to/context-2`

## Configuration

- **Batch size**: 5
- **Execution mode**: agent | team
- **Model**: sonnet
- **Language**: English
- **Output directory**: ./expert-panel/

## Rubric

| Criterion     | Scale | Description          |
| ------------- | ----- | -------------------- |
| [criterion-1] | 1-10  | [what this measures] |
| [criterion-2] | 1-10  | [what this measures] |

## Panel

| ID     | Area   | Specialisation   | Status  | Output      |
| ------ | ------ | ---------------- | ------- | ----------- |
| AREA-1 | [area] | [specialisation] | pending | `AREA-1.md` |
| AREA-2 | [area] | [specialisation] | pending | `AREA-2.md` |

## Consolidation

- **Status**: pending
- **Output**: `consolidated-panel-report.md`

## Execution log

- [YYYY-MM-DD HH:MM] Manifest created
```

**Confirm the manifest with the user before proceeding to Phase 1.**

---

## Phase 1: Independent evaluation

### Launching evaluators

Process evaluators in batches of `batch_size`. Use the configured `execution_mode` to launch each
evaluator. Do NOT use `claude -p` via Bash under any circumstances.

#### Mode: `agent` (default)

Use the **Agent tool** to spawn each evaluator as an independent subagent.

Agent tool parameters for each evaluator:

- **subagent_type**: `general-purpose`
- **model**: Use the configured model (default: sonnet). Never inherit the orchestrator's model.
  Specify the model explicitly in every Agent tool call.
- **mode**: `bypassPermissions` (evaluators only write their own output file)
- **run_in_background**: `true` (enables parallel execution within each batch)
- **description**: Short label, e.g., "Evaluator DFIR-1"
- **prompt**: The complete, self-contained evaluator prompt (see template below)

Launch all evaluators in a batch in a **single message** with multiple Agent tool calls. This is how
parallel execution works — multiple Agent calls in one response.

#### Mode: `team`

Use **TeamCreate** to spawn each evaluator as an independent team member.

- **team_name**: Use the evaluator ID (e.g., "DFIR-1", "SEC-3")
- **model**: Use the configured model (default: sonnet)
- **prompt**: The complete, self-contained evaluator prompt (same as agent mode)

Launch all evaluators in a batch in a single message with multiple TeamCreate calls. Use
**SendMessage** to check on team members if needed. Team members persist until explicitly deleted,
which is useful for follow-up questions or debate phases.

### Evaluator prompt template

Each evaluator agent receives a self-contained prompt with:

1. **Persona**: "You are [ID], an independent expert in [specialisation] within [area]."
2. **Task**: "Evaluate the following artifact from your specialist perspective."
3. **Artifact**: Full path(s) to read
4. **Context**: Full path(s) to additional material
5. **Rubric**: The complete evaluation criteria with scale definitions
6. **Output format**: The exact template from `references/evaluator-output-template.md`
7. **Output path**: Where to write the result
8. **Independence instruction**: "Produce your own assessment. Do not attempt to anticipate or align
   with other evaluators. Genuine disagreement is valuable."

The prompt must be **complete and self-contained** — the evaluator agent has no memory of the
orchestrator's conversation.

### Batch execution

```
Batch 1: [DFIR-1, DFIR-2, DFIR-3, SEC-1, SEC-2] → launch in parallel, wait for completion
Batch 2: [SEC-3, QA-1, QA-2, QA-3, QA-4]        → launch in parallel, wait for completion
...
```

As each agent completes, update the manifest:

- Set evaluator status to `completed` or `failed`
- Log the completion timestamp

If the session is interrupted, the manifest shows which evaluators finished. On resume, skip
completed evaluators and continue from the next pending one.

### Handling failures

If an evaluator agent fails (timeout, error, empty output):

1. Mark as `failed` in the manifest
2. Log the failure reason
3. Continue with remaining evaluators
4. After all batches complete, offer to retry failed evaluators

---

## Phase 2: Quality verification

After all evaluators complete (or after each batch, if preferred), verify each output against the
Definition of Done.

### Definition of Done (DoD) for each evaluation

- [ ] File exists and is not empty
- [ ] Contains a numeric score for **every** criterion in the rubric
- [ ] Contains a written justification for **every** score
- [ ] Contains a specific observations section (errors, omissions, etc.)
- [ ] Contains an expert opinion section (2-3 paragraphs minimum)
- [ ] File is not truncated (ends with the closing marker)

### Verification method

For each completed evaluation, perform a lightweight check. This can be done by the orchestrator
directly (read the file and verify structure) or by spawning a haiku agent for cost efficiency.

If an evaluation fails DoD:

1. Mark as `failed` in the manifest with reason
2. Offer to re-run the evaluator

---

## Phase 3: Consolidation

Once all evaluators have completed and passed DoD, use the **Agent tool** (not `claude -p` or Bash)
to launch a single consolidation agent that:

1. Reads ALL individual evaluation reports
2. Extracts and aggregates scores (mean, min, max per criterion and per area)
3. Identifies consensus findings (flagged by majority of evaluators)
4. Preserves dissenting opinions (where evaluators genuinely disagree)
5. Lists factual errors, omissions, and other specific observations with frequency counts
6. Produces cost/value assessment if applicable
7. Writes a panel conclusion suitable for stakeholder presentation

### Consolidation agent configuration

- **model**: sonnet (or the configured model)
- **Input**: All individual evaluation files + the manifest
- **Output**: `<output_dir>/consolidated-panel-report.md`

### Consolidated report structure

```markdown
# Consolidated Expert Panel Report

_Date: YYYY-MM-DD_ _Panel: N evaluators across M areas_ _Artifact: [description]_

## Executive summary

[3-4 paragraphs: consensus, key concerns, overall assessment]

## Score summary

[Tables: scores by evaluator, by area, panel averages]

## Score distribution analysis

[Consensus vs divergence, score ranges]

## Consensus findings

[Findings flagged by majority, with frequency counts]

## Dissenting opinions

[Where evaluators disagreed and why — this adds credibility]

## Specific observations

[Consolidated lists of errors, omissions, etc. with frequency]

## Recommendations

[Synthesised from all evaluators]

## Panel conclusion

[2-3 paragraphs, suitable for executive presentation]
```

After writing the consolidated report:

- Update manifest consolidation status to `completed`
- Log completion timestamp
- Inform the user that the evaluation is complete

---

## Phase 4 (Optional): Debate

Only execute if the user explicitly requests it. Warn that debate can reduce genuine divergence
through conformity pressure — the primary value of independent panels is preserved disagreement.

If requested:

1. Identify evaluation criteria where scores diverge by more than 2 points
2. For each divergent criterion, launch a debate agent that:
   - Reads the dissenting evaluations
   - Asks each "side" to defend their position
   - Produces a synthesis without forcing agreement
3. Append debate results to the consolidated report

---

## Resumability

The evaluation manifest enables resuming interrupted evaluations:

1. Read the manifest
2. Identify evaluators with `status: pending` or `status: failed`
3. Skip `status: completed` evaluators
4. Continue from the next pending batch
5. If all evaluators are complete but consolidation is pending, go to Phase 3

When resuming, inform the user: "Found existing manifest with X/Y evaluators completed. Continuing
from where we left off."

---

## Reference files

The `references/` directory contains templates and defaults:

- `references/panel-templates/` — Suggested panel compositions by artifact type. Read the relevant
  template when the user describes what they want to evaluate.
- `references/rubric-templates/` — Suggested evaluation criteria and scales. Read the relevant
  template when configuring the rubric.
- `references/evaluator-output-template.md` — The exact output format every evaluator must follow.
  Include this verbatim in every evaluator's prompt.

---

## Cost management

Evaluators are the bulk of the cost. Key controls:

- Use **sonnet** for evaluators by default, not opus. Evaluators need good judgement but not maximum
  reasoning depth.
- Use **haiku** for quality verification (DoD checks) — it only needs to verify structure.
- Use **sonnet** for consolidation — it needs to synthesise across all reports.
- The orchestrator (likely opus) only manages the workflow; it does not perform evaluations.
- Each evaluator reads the artifact + context once. Minimise context by only including files
  relevant to that evaluator's specialisation when possible.

## Anti-patterns

- **Never** have one agent write multiple evaluations. This produces role-play, not independent
  assessment. The evaluations will show artificial consensus and anchoring to the first opinion.
- **Never** share evaluation outputs between evaluators during Phase 1. Independence requires
  isolation.
- **Never** skip the manifest. Without it, interrupted evaluations cannot resume and work is lost.
- **Never** use the orchestrator's model for evaluators unless explicitly requested. It wastes
  budget without improving evaluation quality.
- **Never** use `claude -p` via Bash to launch evaluators. It does not provide isolated context
  windows, writes to stdout instead of files, and may use unsupported CLI flags. Always use the
  Agent tool.
