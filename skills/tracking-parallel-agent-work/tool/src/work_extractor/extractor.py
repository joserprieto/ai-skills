"""Main extraction logic — orchestrates parsing and grouping."""

from __future__ import annotations

from datetime import date
from zoneinfo import ZoneInfo

from work_extractor.config import Config
from work_extractor.models import DaySummary, WorkBlock
from work_extractor.parsers.claude_code import find_jsonl_files, parse_session


def extract_blocks(
    config: Config,
    date_from: date,
    date_to: date,
) -> list[WorkBlock]:
    """Extract all work blocks within a date range.

    Dates are interpreted in the configured timezone.
    """
    tz = ZoneInfo(config.timezone)
    jsonl_files = find_jsonl_files(config.search_path)

    all_blocks: list[WorkBlock] = []

    for jsonl_path in jsonl_files:
        blocks = parse_session(jsonl_path, config.gap_threshold_minutes)
        for block in blocks:
            block_local_start = block.start_utc.replace(tzinfo=ZoneInfo("UTC")).astimezone(tz)
            block_date = block_local_start.date()
            if date_from <= block_date <= date_to:
                all_blocks.append(block)

    all_blocks.sort(key=lambda b: b.start_utc)
    return all_blocks


def group_by_day(
    blocks: list[WorkBlock],
    timezone: str,
) -> list[DaySummary]:
    """Group work blocks by local date."""
    tz = ZoneInfo(timezone)
    days: dict[str, DaySummary] = {}

    for block in blocks:
        block_local_start = block.start_utc.replace(tzinfo=ZoneInfo("UTC")).astimezone(tz)
        day_str = block_local_start.date().isoformat()

        if day_str not in days:
            days[day_str] = DaySummary(date=day_str, timezone=timezone)
        days[day_str].blocks.append(block)

    return [days[k] for k in sorted(days.keys())]


def list_sessions(
    config: Config,
    target_date: date,
) -> list[dict]:
    """List all sessions that have activity on a given date."""
    tz = ZoneInfo(config.timezone)
    jsonl_files = find_jsonl_files(config.search_path)

    sessions = []
    for jsonl_path in jsonl_files:
        blocks = parse_session(jsonl_path, config.gap_threshold_minutes)
        for block in blocks:
            block_local_start = block.start_utc.replace(tzinfo=ZoneInfo("UTC")).astimezone(tz)
            if block_local_start.date() == target_date:
                sessions.append({
                    "session_id": block.session_id,
                    "project_path": block.project_path,
                    "account": block.account,
                    "profile": block.profile,
                    "start_local": block_local_start.isoformat(),
                    "duration_minutes": block.duration_minutes,
                    "first_message": block.first_user_message[:100],
                })
                break  # one entry per session

    return sessions
