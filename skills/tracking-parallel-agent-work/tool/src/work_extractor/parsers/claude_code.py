"""Parser for Claude Code JSONL conversation logs."""

from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path

from work_extractor.models import WorkBlock

# Pattern to extract account/profile from JSONL path
# ~/.ai/claude-code/accounts/{account}/profiles/{profile}/projects/{project}/{session}.jsonl
PATH_PATTERN = re.compile(
    r"accounts/(?P<account>[^/]+)/profiles/(?P<profile>[^/]+)/projects/(?P<project>[^/]+)/"
)

RELEVANT_TYPES = {"user", "assistant"}


def extract_user_text(content) -> str | None:
    """Extract human-readable text from user message content."""
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    return item["text"].strip()
                if item.get("type") == "tool_result":
                    continue
    return None


def extract_tool_names(content) -> list[str]:
    """Extract tool names from assistant message content."""
    tools = []
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and item.get("type") == "tool_use":
                tools.append(item.get("name", "unknown"))
    return tools


def parse_session(
    jsonl_path: Path,
    gap_threshold_minutes: int = 30,
) -> list[WorkBlock]:
    """Parse a single JSONL session file into work blocks.

    A new block starts when:
    - It's the first user message (text, not tool_result)
    - There's a gap > gap_threshold between consecutive messages
    """
    path_match = PATH_PATTERN.search(str(jsonl_path))
    if not path_match:
        return []

    account = path_match.group("account")
    profile = path_match.group("profile")
    session_id = jsonl_path.stem

    # Project path is extracted from the `cwd` field of entries (not from the
    # directory name, which uses an ambiguous encoding where `-` replaces `/`
    # but directory names can also contain `-`).
    project_path = ""

    entries = []
    with open(jsonl_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("type") not in RELEVANT_TYPES:
                continue
            timestamp_str = entry.get("timestamp")
            if not timestamp_str:
                continue
            if not project_path and entry.get("cwd"):
                project_path = entry["cwd"]
            try:
                ts = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
                ts = ts.replace(tzinfo=None)  # store as naive UTC
            except ValueError:
                continue
            entries.append(entry | {"_ts": ts})

    if not entries:
        return []

    entries.sort(key=lambda e: e["_ts"])

    blocks: list[WorkBlock] = []
    current_block: WorkBlock | None = None
    last_ts: datetime | None = None

    for entry in entries:
        ts = entry["_ts"]
        entry_type = entry["type"]
        message = entry.get("message", {})
        content = message.get("content", "")

        gap_exceeded = (
            last_ts is not None
            and (ts - last_ts).total_seconds() > gap_threshold_minutes * 60
        )

        if gap_exceeded and current_block is not None:
            blocks.append(current_block)
            current_block = None

        if current_block is None:
            user_text = ""
            if entry_type == "user":
                user_text = extract_user_text(content) or ""

            current_block = WorkBlock(
                session_id=session_id,
                project_path=project_path,
                account=account,
                profile=profile,
                start_utc=ts,
                end_utc=ts,
                first_user_message=user_text[:200],
                model=message.get("model", ""),
            )

        current_block.end_utc = ts

        if entry_type == "user":
            current_block.message_count["user"] += 1
            text = extract_user_text(content)
            if text:
                if not current_block.first_user_message:
                    current_block.first_user_message = text[:200]
                current_block.user_messages.append(text)
        elif entry_type == "assistant":
            current_block.message_count["assistant"] += 1
            if not current_block.model:
                current_block.model = message.get("model", "")
            for tool_name in extract_tool_names(content):
                current_block.tools_used[tool_name] = (
                    current_block.tools_used.get(tool_name, 0) + 1
                )
            usage = message.get("usage", {})
            current_block.token_usage["input"] += usage.get("input_tokens", 0)
            current_block.token_usage["output"] += usage.get("output_tokens", 0)
            current_block.token_usage["cache_creation"] += usage.get(
                "cache_creation_input_tokens", 0
            )
            current_block.token_usage["cache_read"] += usage.get(
                "cache_read_input_tokens", 0
            )

        last_ts = ts

    if current_block is not None:
        blocks.append(current_block)

    return blocks


def find_jsonl_files(search_pattern: str) -> list[Path]:
    """Find all JSONL files matching the search pattern."""
    from glob import glob

    pattern = search_pattern.rstrip("/") + "/*.jsonl"
    expanded = str(Path(pattern).expanduser()) if "~" in pattern else pattern
    return sorted(Path(p) for p in glob(expanded, recursive=False))
