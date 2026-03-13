"""JSON output formatter."""

from __future__ import annotations

import json

from work_extractor.config import SamplingConfig
from work_extractor.models import DaySummary


def format_days(
    days: list[DaySummary],
    pricing: dict[str, dict[str, float]] | None = None,
    sampling: SamplingConfig | None = None,
) -> str:
    """Format day summaries as JSON."""
    data = [day.to_dict(pricing, sampling) for day in days]
    return json.dumps(data, indent=2, ensure_ascii=False)
