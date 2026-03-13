"""Tests for the extractor module."""

from datetime import datetime

from work_extractor.config import Config, SamplingConfig
from work_extractor.extractor import group_by_day
from work_extractor.models import WorkBlock
from work_extractor.pricing import estimate_cost


SONNET_PRICING = {
    "claude-sonnet-4-6": {
        "input": 3.0,
        "output": 15.0,
        "cache_write": 3.75,
        "cache_read": 0.30,
    },
}

HAIKU_PRICING = {
    "claude-haiku-4-5-20251001": {
        "input": 1.0,
        "output": 5.0,
        "cache_write": 1.25,
        "cache_read": 0.10,
    },
}

ALL_PRICING = {**SONNET_PRICING, **HAIKU_PRICING}


class TestGroupByDay:
    def test_single_block_single_day(self):
        blocks = [
            WorkBlock(
                session_id="s1",
                project_path="/test",
                account="test",
                profile="standard",
                start_utc=datetime(2026, 3, 10, 10, 0, 0),
                end_utc=datetime(2026, 3, 10, 11, 0, 0),
                first_user_message="test",
            )
        ]
        days = group_by_day(blocks, "Europe/Madrid")
        assert len(days) == 1
        assert days[0].date == "2026-03-10"
        assert len(days[0].blocks) == 1

    def test_blocks_across_midnight_utc(self):
        """A block at 23:30 UTC is 00:30 CET next day."""
        blocks = [
            WorkBlock(
                session_id="s1",
                project_path="/test",
                account="test",
                profile="standard",
                start_utc=datetime(2026, 3, 10, 23, 30, 0),
                end_utc=datetime(2026, 3, 11, 0, 30, 0),
                first_user_message="late night",
            )
        ]
        days = group_by_day(blocks, "Europe/Madrid")
        assert len(days) == 1
        # CET = UTC+1, so 23:30 UTC = 00:30 CET March 11
        assert days[0].date == "2026-03-11"

    def test_multiple_days(self):
        blocks = [
            WorkBlock(
                session_id="s1",
                project_path="/test",
                account="test",
                profile="standard",
                start_utc=datetime(2026, 3, 10, 10, 0, 0),
                end_utc=datetime(2026, 3, 10, 11, 0, 0),
                first_user_message="morning",
            ),
            WorkBlock(
                session_id="s2",
                project_path="/test",
                account="test",
                profile="standard",
                start_utc=datetime(2026, 3, 11, 14, 0, 0),
                end_utc=datetime(2026, 3, 11, 15, 0, 0),
                first_user_message="next day",
            ),
        ]
        days = group_by_day(blocks, "Europe/Madrid")
        assert len(days) == 2
        assert days[0].date == "2026-03-10"
        assert days[1].date == "2026-03-11"


class TestConfigLoad:
    def test_bundled_config_loads(self):
        config = Config.load()
        assert "claude-opus-4-6" in config.pricing
        assert "claude-sonnet-4-6" in config.pricing
        assert config.pricing["claude-opus-4-6"]["input"] == 5.0
        assert config.sampling.first_messages == 3

    def test_custom_config_file(self, tmp_path):
        custom = tmp_path / "custom.yaml"
        custom.write_text(
            "timezone: America/New_York\n"
            "gap_threshold_minutes: 60\n"
            "sampling:\n"
            "  first_messages: 5\n"
            "  max_total_messages: 20\n"
            "pricing:\n"
            "  my-model:\n"
            "    input: 10.0\n"
            "    output: 50.0\n"
        )
        config = Config.load(custom)
        assert config.timezone == "America/New_York"
        assert config.gap_threshold_minutes == 60
        assert config.sampling.first_messages == 5
        assert config.sampling.max_total_messages == 20
        assert "my-model" in config.pricing
        assert "claude-opus-4-6" not in config.pricing

    def test_missing_file_falls_back_to_bundled(self, tmp_path):
        missing = tmp_path / "nope.yaml"
        config = Config.load(missing)
        assert "claude-opus-4-6" in config.pricing


class TestEstimateCost:
    def test_known_model(self):
        cost = estimate_cost("claude-sonnet-4-6", 1_000_000, 100_000, pricing=SONNET_PRICING)
        assert cost == 3.0 + 1.5

    def test_with_cache_tokens(self):
        cost = estimate_cost(
            "claude-sonnet-4-6", 0, 0,
            cache_creation_tokens=1_000_000,
            cache_read_tokens=1_000_000,
            pricing=SONNET_PRICING,
        )
        assert cost == 3.75 + 0.30

    def test_unknown_model(self):
        assert estimate_cost("unknown-model", 1000, 500, pricing=SONNET_PRICING) is None

    def test_no_pricing_returns_none(self):
        assert estimate_cost("claude-sonnet-4-6", 1000, 500) is None

    def test_zero_tokens(self):
        cost = estimate_cost("claude-sonnet-4-6", 0, 0, pricing=SONNET_PRICING)
        assert cost == 0.0


class TestDaySummaryAggregation:
    def test_tokens_and_cost_aggregation(self):
        blocks = [
            WorkBlock(
                session_id="s1",
                project_path="/test",
                account="acct-1",
                profile="standard",
                start_utc=datetime(2026, 3, 10, 10, 0, 0),
                end_utc=datetime(2026, 3, 10, 11, 0, 0),
                first_user_message="test",
                model="claude-sonnet-4-6",
                token_usage={
                    "input": 100_000,
                    "output": 20_000,
                    "cache_creation": 50_000,
                    "cache_read": 200_000,
                },
            ),
            WorkBlock(
                session_id="s2",
                project_path="/test2",
                account="acct-2",
                profile="standard",
                start_utc=datetime(2026, 3, 10, 14, 0, 0),
                end_utc=datetime(2026, 3, 10, 15, 0, 0),
                first_user_message="test2",
                model="claude-haiku-4-5-20251001",
                token_usage={
                    "input": 200_000,
                    "output": 50_000,
                    "cache_creation": 0,
                    "cache_read": 0,
                },
            ),
        ]
        days = group_by_day(blocks, "Europe/Madrid")
        assert len(days) == 1
        day = days[0]

        assert day.total_tokens == {
            "input": 300_000,
            "output": 70_000,
            "cache_creation": 50_000,
            "cache_read": 200_000,
        }
        assert day.models_used == ["claude-haiku-4-5-20251001", "claude-sonnet-4-6"]
        assert day.accounts_used == ["acct-1", "acct-2"]

        # Cost: sonnet 0.8475 + haiku 0.45 = 1.2975
        assert abs(day.total_cost(ALL_PRICING) - 1.2975) < 0.001

        d = day.to_dict(ALL_PRICING)
        assert "total_tokens" in d
        assert "models_used" in d
        assert "accounts_used" in d
        assert "estimated_cost_usd" in d
