# Design Decisions

Lightweight record of key design decisions for the work-extractor tool.

## DD-001: Project path from `cwd` field, not directory name

**Date**: 2026-03-12 **Status**: Accepted

Claude Code encodes project paths in directory names by replacing `/` with `-` and prefixing with
`-`. For example, `/Users/jose/Projects/my-app` becomes `-Users-jose-Projects-my-app`.

This encoding is **not reversible** because directory names can contain hyphens natively. The string
`-Users-jose-Projects-my-app` could decode to `/Users/jose/Projects/my/app` or
`/Users/jose/Projects/my-app` — there is no way to distinguish.

**Decision**: Extract `project_path` from the `cwd` field present in JSONL entries instead of
attempting to decode the directory name.

## DD-002: Gap-based block splitting

**Date**: 2026-03-12 **Status**: Accepted

A single JSONL session file can span an entire day with multiple unrelated work periods. Naive
treatment as a single block would produce meaningless duration and topic data.

**Decision**: Split sessions into blocks when the gap between consecutive messages exceeds a
configurable threshold (default: 30 minutes). This aligns with how humans perceive "work sessions" —
a 2-hour gap means you switched context, even within the same Claude Code session.

## DD-003: Cache token tracking for cost estimation

**Date**: 2026-03-12 **Status**: Accepted

Claude Code JSONL entries contain four token categories in the `message.usage` field:

- `input_tokens`: standard (non-cached) input
- `output_tokens`: model output
- `cache_creation_input_tokens`: tokens used to create prompt cache (1.25x input price)
- `cache_read_input_tokens`: tokens read from prompt cache (0.1x input price)

In real sessions, **95%+ of input tokens are cache reads**. Ignoring cache tokens would
underestimate costs by 10-50x.

**Decision**: Track all four token types separately. Calculate costs using differentiated rates per
token type. The pricing table includes `cache_write` and `cache_read` rates per model.

## DD-004: External pricing configuration

**Date**: 2026-03-12 **Status**: Accepted

Hardcoding model pricing in source code creates a maintenance burden — prices change, new models are
released.

**Decision**: Store pricing in the `config.yaml` file under the `pricing` key. A bundled default
ships with the package. Users can override with `--config` pointing to a custom YAML file. All CLI
flags override config file values.

## DD-005: Message sampling strategy

**Date**: 2026-03-12 **Status**: Accepted

**Problem**: To enable LLM-based summarization of work blocks, we need semantic context — what the
user asked for, what was discussed. However, capturing all user messages is not viable:

| Block duration | Human messages | Text volume |
| -------------- | -------------- | ----------- |
| < 30 min       | 1-5            | < 2 KB      |
| 1-2 hours      | 10-25          | 15-50 KB    |
| 3+ hours       | 30-60          | 70-130 KB   |

A full day (18 blocks) produced ~615 KB of user text alone.

**Decision**: Sample messages using a three-zone strategy:

1. **First N** messages (default 3): capture initial intent
2. **Last N** messages (default 2): capture where the work ended
3. **Uniform sample** from the middle: fill remaining slots up to `max_total_messages` (default 10)

Additional guards:

- `max_chars_per_message` (default 500): truncate individual messages
- `max_chars_total` (default 5000): hard cap on total text per block

This yields ~5 KB per block, ~90 KB per day — well within LLM context limits.

**Alternatives considered**:

- _Capture everything_: volume too high for LLM processing
- _Time-based segmentation_ (segment block into 15-min windows, pick 2 messages per window):
  rejected — overlapping rules (min gap, max segments) created hard-to-reason-about logic. Uniform
  sampling achieves similar coverage with simpler implementation.
- _LLM-generated summaries at extraction time_: adds API cost and latency; deferred to a potential
  future `summarize` command.

## DD-006: Only user messages, not assistant messages

**Date**: 2026-03-12 **Status**: Accepted

**Context**: Assistant messages contain valuable semantic context (explanations, reasoning,
decisions). However, they are significantly larger than user messages (tool_use blocks, code
snippets, long explanations) and would blow up the sampling budget.

**Decision**: Sample only user text messages (excluding `tool_result` entries). User messages
capture the "what was requested" dimension, which is sufficient for work tracking purposes.
Assistant content can be retrieved from the original JSONL if deeper analysis is needed.

This decision may be revisited if a `summarize` command is added that processes the full
conversation through an LLM.
