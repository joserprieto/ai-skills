"""Data models for work extraction."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime

from work_extractor.config import SamplingConfig
from work_extractor.pricing import estimate_cost
from work_extractor.sampling import sample_messages


@dataclass
class WorkBlock:
    """A continuous block of work within a single session."""

    session_id: str
    project_path: str
    account: str
    profile: str
    start_utc: datetime
    end_utc: datetime
    first_user_message: str
    model: str = ""
    tools_used: dict[str, int] = field(default_factory=dict)
    message_count: dict[str, int] = field(default_factory=lambda: {"user": 0, "assistant": 0})
    token_usage: dict[str, int] = field(
        default_factory=lambda: {
            "input": 0,
            "output": 0,
            "cache_creation": 0,
            "cache_read": 0,
        }
    )
    user_messages: list[str] = field(default_factory=list)

    @property
    def duration_minutes(self) -> int:
        delta = self.end_utc - self.start_utc
        return int(delta.total_seconds() / 60)

    @property
    def total_tokens(self) -> int:
        return sum(self.token_usage.values())

    def cost(self, pricing: dict[str, dict[str, float]] | None = None) -> float | None:
        return estimate_cost(
            self.model,
            self.token_usage["input"],
            self.token_usage["output"],
            self.token_usage.get("cache_creation", 0),
            self.token_usage.get("cache_read", 0),
            pricing=pricing,
        )

    def to_dict(
        self,
        pricing: dict[str, dict[str, float]] | None = None,
        sampling: SamplingConfig | None = None,
    ) -> dict:
        sampled = (
            sample_messages(self.user_messages, sampling)
            if sampling
            else self.user_messages
        )
        result = {
            "session_id": self.session_id,
            "project_path": self.project_path,
            "account": self.account,
            "profile": self.profile,
            "start_utc": self.start_utc.isoformat() + "Z",
            "end_utc": self.end_utc.isoformat() + "Z",
            "duration_minutes": self.duration_minutes,
            "first_user_message": self.first_user_message,
            "model": self.model,
            "tools_used": self.tools_used,
            "message_count": self.message_count,
            "token_usage": self.token_usage,
            "total_tokens": self.total_tokens,
            "user_messages_sample": sampled,
        }
        c = self.cost(pricing)
        if c is not None:
            result["estimated_cost_usd"] = round(c, 6)
        return result


@dataclass
class DaySummary:
    """Aggregation of work blocks for a single day."""

    date: str
    timezone: str
    blocks: list[WorkBlock] = field(default_factory=list)

    @property
    def total_duration_minutes(self) -> int:
        return sum(b.duration_minutes for b in self.blocks)

    @property
    def projects(self) -> list[dict]:
        project_durations: dict[str, int] = {}
        for block in self.blocks:
            project_durations[block.project_path] = (
                project_durations.get(block.project_path, 0) + block.duration_minutes
            )
        return [
            {"path": path, "duration_minutes": mins}
            for path, mins in sorted(project_durations.items(), key=lambda x: -x[1])
        ]

    @property
    def total_tokens(self) -> dict[str, int]:
        totals = {"input": 0, "output": 0, "cache_creation": 0, "cache_read": 0}
        for block in self.blocks:
            for key in totals:
                totals[key] += block.token_usage.get(key, 0)
        return totals

    @property
    def models_used(self) -> list[str]:
        return sorted({b.model for b in self.blocks if b.model})

    @property
    def accounts_used(self) -> list[str]:
        return sorted({b.account for b in self.blocks if b.account})

    def total_cost(self, pricing: dict[str, dict[str, float]] | None = None) -> float:
        total = 0.0
        for block in self.blocks:
            c = block.cost(pricing)
            if c is not None:
                total += c
        return total

    def to_dict(
        self,
        pricing: dict[str, dict[str, float]] | None = None,
        sampling: SamplingConfig | None = None,
    ) -> dict:
        tokens = self.total_tokens
        return {
            "date": self.date,
            "timezone": self.timezone,
            "total_blocks": len(self.blocks),
            "total_duration_minutes": self.total_duration_minutes,
            "total_tokens": tokens,
            "total_tokens_combined": sum(tokens.values()),
            "models_used": self.models_used,
            "accounts_used": self.accounts_used,
            "estimated_cost_usd": round(self.total_cost(pricing), 6),
            "projects": self.projects,
            "blocks": [b.to_dict(pricing, sampling) for b in self.blocks],
        }
