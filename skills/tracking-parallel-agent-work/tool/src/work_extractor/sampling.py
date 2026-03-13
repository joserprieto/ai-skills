"""Message sampling — select representative user messages from a work block."""

from __future__ import annotations

from work_extractor.config import SamplingConfig


def sample_messages(
    messages: list[str],
    config: SamplingConfig,
) -> list[str]:
    """Select a representative sample of user messages.

    Strategy:
      1. Take the first N messages (initial intent).
      2. Take the last N messages (where work ended).
      3. Fill remaining slots with uniformly spaced messages from the middle.
      4. Truncate individual messages and enforce total char budget.
    """
    total = len(messages)
    if total == 0:
        return []

    max_msgs = config.max_total_messages

    if total <= max_msgs:
        selected = list(range(total))
    else:
        first_n = min(config.first_messages, total)
        last_n = min(config.last_messages, total)

        first_indices = set(range(first_n))
        last_indices = set(range(total - last_n, total))
        fixed = first_indices | last_indices

        remaining_slots = max_msgs - len(fixed)
        middle_candidates = [i for i in range(total) if i not in fixed]

        if remaining_slots > 0 and middle_candidates:
            step = max(1, len(middle_candidates) // (remaining_slots + 1))
            sampled = set()
            for offset in range(step, len(middle_candidates), step):
                if len(sampled) >= remaining_slots:
                    break
                sampled.add(middle_candidates[offset])
            fixed |= sampled

        selected = sorted(fixed)

    result = []
    chars_remaining = config.max_chars_total
    for idx in selected:
        msg = messages[idx]
        if len(msg) > config.max_chars_per_message:
            msg = msg[: config.max_chars_per_message] + "..."
        if chars_remaining <= 0:
            break
        if len(msg) > chars_remaining:
            msg = msg[:chars_remaining] + "..."
            chars_remaining = 0
        else:
            chars_remaining -= len(msg)
        result.append(msg)

    return result
