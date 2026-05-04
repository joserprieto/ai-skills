---
type: proposal
status: draft
created: 2026-04-15
author: joserprieto
source_project: 'ACOPLA/TGM canonical domain rewrite'
---

# Proposal — defensive-monitoring-timeout

A companion watchdog pattern for background teammates dispatched via the `Agent` tool with
`run_in_background: true`. Catches silent failures (context exhaustion, stalls, premature death)
within a bounded window instead of requiring human intervention.

---

## Problem statement

When a coordinator dispatches a background teammate via `Agent` with `run_in_background: true`, the
framework promises an `idle_notification` when the teammate finishes. In practice, three failure
modes produce **no notification at all**:

1. **Context exhaustion** — the teammate hits its token limit mid-task. The subprocess terminates or
   hangs without emitting a completion signal. The coordinator receives silence.

2. **Silent stall** — the teammate is technically alive but has stopped producing output: stuck
   reading a very large file tree, looping in reasoning, or waiting on a tool call that never
   returns. No timeout fires on the framework side.

3. **Premature death** — the subprocess dies at initialisation or very early in execution (e.g. a
   crash in model loading or a failed tool bootstrap) before it has a chance to report back.

In all three cases the coordinator, correctly following the official guidance _"do NOT sleep, poll,
or proactively check on its progress"_, waits indefinitely for a notification that will never
arrive.

---

## Why the official guidance is insufficient (in isolation)

The "do not poll" rule is sound: sleeping wastes cache budget, and naive polling burns tokens on
every check even when the teammate is working normally. The rule optimises for the **happy path**
where teammates always signal completion.

The failure modes above break that assumption. A teammate that dies at init will never signal. One
that exhausts context mid-task will be cut off before it can summarise or hand off. The coordinator
has no way to distinguish "still working" from "gone" without an external signal.

The fix is not to violate the no-poll rule for the coordinator's main turn — it is to delegate the
polling concern to a **lightweight companion monitor** that runs out-of-band, surfaces progress or
stall signals as chat events, and lets the coordinator react only when something meaningful changes.

---

## Proposed pattern — defensive monitoring timeout

### Companion Monitor setup

For every background teammate dispatched, the coordinator immediately starts a companion watchdog
using the `Monitor` tool with `persistent: true`. The monitor polls a measurable proxy signal
(output file count, log line count, target file size) and emits structured lines that the
coordinator can act on.

### Example Monitor command

```bash
#!/usr/bin/env bash
# Watchdog for a background teammate writing files to $OUTPUT_DIR.
# Emits PROGRESS when the signal grows, STALL when it is unchanged for
# STALL_THRESHOLD consecutive checks.

OUTPUT_DIR="${OUTPUT_DIR:-/tmp/teammate-output}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"       # seconds between checks
STALL_THRESHOLD="${STALL_THRESHOLD:-10}"    # consecutive unchanged checks = stall

prev_count=0
stall_count=0

while true; do
  current_count=$(find "$OUTPUT_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [ "$current_count" -gt "$prev_count" ]; then
    echo "PROGRESS files=$current_count delta=$((current_count - prev_count))"
    stall_count=0
    prev_count="$current_count"
  else
    stall_count=$((stall_count + 1))
    echo "CHECK files=$current_count stall_count=$stall_count/${STALL_THRESHOLD}"
    if [ "$stall_count" -ge "$STALL_THRESHOLD" ]; then
      echo "STALL files=$current_count unchanged for $((stall_count * CHECK_INTERVAL))s"
      # Reset so the coordinator can choose to continue monitoring after intervening
      stall_count=0
    fi
  fi

  sleep "$CHECK_INTERVAL"
done
```

### Recommended defaults

| Parameter         | Default    | Rationale                                                              |
| ----------------- | ---------- | ---------------------------------------------------------------------- |
| `CHECK_INTERVAL`  | 60s        | One check per minute; low noise, stays within prompt cache TTL (5 min) |
| `STALL_THRESHOLD` | 10         | 10 × 60s = 10 minutes before a STALL fires; avoids false positives     |
| Proxy signal      | file count | Works for most generation tasks; see Open Questions for alternatives   |

### Coordinator reaction to STALL events

When the coordinator observes a `STALL` line, it has three options in escalating order:

1. **Nudge** — send a `SendMessage` to the teammate asking for a status update. Appropriate when the
   teammate is still alive and may be stuck in a long reasoning step.

2. **Respawn with continuation** — kill the stalled teammate (or simply stop waiting for it), then
   launch a new `Agent` call with a continuation prompt that reads already-written output and picks
   up from where the previous run stopped. Appropriate when context exhaustion is suspected.

3. **Coordinator takeover** — the coordinator itself reads the partial output and finishes the task.
   Appropriate when the remaining work is small or the teammate has died irrecoverably.

### Teardown

When the teammate completes normally (the coordinator receives `idle_notification`), it calls
`TaskStop` on the companion monitor to terminate the watchdog loop. Do not leave monitors running
after their subject has completed — they accumulate chat turns.

---

## Real-world example

**Project**: ACOPLA/TGM canonical domain rewrite — `question-extractor` teammate batch **Date**:
2026-04-15

Three consecutive `question-extractor` teammates were dispatched to extract domain questions from
specification documents:

- **v1** hit context limit mid-task. No notification was emitted. The coordinator waited.
- **v2** died at initialisation (subprocess crash). No notification. Coordinator still waited.
- **v3** died shortly after init. No notification.

The stall was only discovered when the human user asked for a status update — roughly 30–40 minutes
after the last teammate had died. No output had been produced.

After adding the defensive monitor (file-count proxy against the output directory, 60s interval,
10-minute stall threshold), a subsequent dispatch was caught within 10 minutes of stalling, allowing
the coordinator to respawn with a continuation prompt and recover the session without further human
intervention.

---

## Implementation notes

### Tools involved

| Tool                                | Role                                                     |
| ----------------------------------- | -------------------------------------------------------- |
| `Agent` + `run_in_background: true` | Dispatches the primary teammate                          |
| `Monitor` + `persistent: true`      | Runs the watchdog loop as a long-lived companion process |
| `TaskStop`                          | Terminates the monitor on successful teammate completion |
| `SendMessage`                       | Delivers nudge to a stalled (but alive) teammate         |

### Caveats

- **Monitor events count as chat turns.** Each line the monitor emits is a notification that lands
  in the coordinator's context. Keep `CHECK_INTERVAL` at 60s or above and avoid chatty `echo`
  statements in the poll loop. A 10-minute stall threshold at 60s interval means at most ~10 CHECK
  lines before a STALL fires — acceptable overhead.

- **The proxy signal must be externally observable.** File count works well. If the teammate writes
  to a single growing file, use `wc -l` or `stat -f%z` (macOS) / `stat -c%s` (Linux) instead. If
  there is no file output, a heartbeat log appended by the teammate is an alternative, but requires
  the teammate to cooperate.

- **Stall threshold tuning.** 10 minutes is conservative for tasks that normally complete in 2–5
  minutes. For longer tasks (30+ minutes expected) consider raising the threshold to 20–30 minutes
  to avoid false positive STALL events mid-run.

- **Multiple teammates.** Each background teammate needs its own companion monitor with its own
  output directory as the proxy signal. Do not share a single monitor across multiple teammates.

---

## Open questions

1. **Standard metric when output is not a file count.** For teammates that produce no file output
   (e.g. pure analysis teammates that return results in their completion message), the file-count
   proxy does not apply. What is the canonical fallback? Options: a heartbeat log file the teammate
   appends to periodically; a progress file the teammate writes with a monotone counter; or
   accepting that those teammates cannot be monitored and documenting the gap.

2. **Wrapper skill or manual pattern?** Should this become a `start-monitored-agent` wrapper skill
   that encapsulates the Monitor setup and teardown, or remain a manual pattern that coordinators
   implement case-by-case? A wrapper would reduce boilerplate but requires a standardised interface
   for the proxy signal.

3. **Universal vs. domain-specific stall threshold.** Is 10 minutes the right default across all
   task types, or should it be parameterised per dispatch? A lightweight extraction task that should
   finish in 2 minutes has very different stall characteristics from a full domain rewrite that may
   legitimately pause for 15 minutes.

4. **Coordinator notification format.** Should the monitor emit structured JSON lines instead of
   plain text (`PROGRESS`, `STALL`, `CHECK`)? Structured output would allow the coordinator to parse
   fields (file count, delta, elapsed) more reliably, but adds complexity to the bash script.

5. **Integration with `tracking-parallel-agent-work` skill.** The existing skill tracks parallel
   agent work time. Can the watchdog signal feed into that tracking, or do they remain independent
   concerns?

---

## Acceptance criteria for promoting proposal → skill

Before this document becomes `skills/defensive-monitoring-timeout/`:

- [ ] The proxy signal question (open question 1) is resolved with at least two canonical metric
      options documented.
- [ ] The pattern has been successfully applied to at least three independent incidents (beyond the
      ACOPLA case study) with documented outcomes.
- [ ] A decision has been made on wrapper skill vs. manual pattern (open question 2).
- [ ] The bash watchdog script has been tested on both macOS (`stat -f%z`) and Linux (`stat -c%s`)
      and the cross-platform differences are handled.
- [ ] Teardown behaviour on coordinator interruption (e.g. the coordinator's own context runs out)
      is specified — what happens to orphaned monitors?
- [ ] The skill frontmatter (`name`, `description`, `license`, `metadata`) is written and matches
      the conventions in `skills/*/SKILL.md`.
