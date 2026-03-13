"""YAML output formatter."""

from __future__ import annotations

import yaml

from work_extractor.config import SamplingConfig
from work_extractor.models import DaySummary


def format_days(
    days: list[DaySummary],
    pricing: dict[str, dict[str, float]] | None = None,
    sampling: SamplingConfig | None = None,
) -> str:
    """Format day summaries as YAML."""
    data = [day.to_dict(pricing, sampling) for day in days]
    return yaml.dump(data, default_flow_style=False, allow_unicode=True, sort_keys=False)
