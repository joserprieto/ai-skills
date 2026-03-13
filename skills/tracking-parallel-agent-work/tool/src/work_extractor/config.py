"""Configuration — loads from config.yaml with CLI overrides."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

import yaml

BUNDLED_CONFIG_PATH = Path(__file__).parent / "config.yaml"

DEFAULT_SEARCH_PATH = "~/.ai/claude-code/accounts/*/profiles/*/projects/*/"
DEFAULT_TIMEZONE = "Europe/Madrid"
DEFAULT_GAP_THRESHOLD_MINUTES = 30
DEFAULT_OUTPUT_FORMAT = "yaml"


@dataclass
class SamplingConfig:
    first_messages: int = 3
    last_messages: int = 2
    max_total_messages: int = 10
    max_chars_per_message: int = 500
    max_chars_total: int = 5000


@dataclass
class Config:
    search_path: str = DEFAULT_SEARCH_PATH
    timezone: str = DEFAULT_TIMEZONE
    gap_threshold_minutes: int = DEFAULT_GAP_THRESHOLD_MINUTES
    output_format: str = DEFAULT_OUTPUT_FORMAT
    sampling: SamplingConfig = field(default_factory=SamplingConfig)
    pricing: dict[str, dict[str, float]] = field(default_factory=dict)

    @property
    def resolved_search_path(self) -> str:
        return str(Path(self.search_path).expanduser())

    @classmethod
    def load(cls, config_path: Path | None = None) -> Config:
        """Load configuration from a YAML file.

        Falls back to the bundled config.yaml if the given path does not exist.
        """
        target = config_path or BUNDLED_CONFIG_PATH
        if not target.exists():
            target = BUNDLED_CONFIG_PATH

        with open(target, encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}

        sampling_data = data.get("sampling", {})
        sampling = SamplingConfig(
            first_messages=sampling_data.get("first_messages", 3),
            last_messages=sampling_data.get("last_messages", 2),
            max_total_messages=sampling_data.get("max_total_messages", 10),
            max_chars_per_message=sampling_data.get("max_chars_per_message", 500),
            max_chars_total=sampling_data.get("max_chars_total", 5000),
        )

        return cls(
            search_path=data.get("search_path", DEFAULT_SEARCH_PATH),
            timezone=data.get("timezone", DEFAULT_TIMEZONE),
            gap_threshold_minutes=data.get("gap_threshold_minutes", DEFAULT_GAP_THRESHOLD_MINUTES),
            output_format=data.get("output_format", DEFAULT_OUTPUT_FORMAT),
            sampling=sampling,
            pricing=data.get("pricing", {}),
        )
