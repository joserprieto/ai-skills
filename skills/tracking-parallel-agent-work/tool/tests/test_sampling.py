"""Tests for message sampling."""

from work_extractor.config import SamplingConfig
from work_extractor.sampling import sample_messages


class TestSampleMessages:
    def test_empty_messages(self):
        config = SamplingConfig()
        assert sample_messages([], config) == []

    def test_fewer_than_max_returns_all(self):
        config = SamplingConfig(max_total_messages=10)
        msgs = ["msg1", "msg2", "msg3"]
        result = sample_messages(msgs, config)
        assert result == msgs

    def test_exactly_max_returns_all(self):
        config = SamplingConfig(max_total_messages=5)
        msgs = [f"msg{i}" for i in range(5)]
        result = sample_messages(msgs, config)
        assert result == msgs

    def test_samples_first_and_last(self):
        config = SamplingConfig(
            first_messages=2,
            last_messages=2,
            max_total_messages=4,
        )
        msgs = [f"msg{i}" for i in range(20)]
        result = sample_messages(msgs, config)
        assert result[0] == "msg0"
        assert result[1] == "msg1"
        assert result[-1] == "msg19"
        assert result[-2] == "msg18"

    def test_includes_middle_samples(self):
        config = SamplingConfig(
            first_messages=2,
            last_messages=2,
            max_total_messages=8,
        )
        msgs = [f"msg{i}" for i in range(20)]
        result = sample_messages(msgs, config)
        assert len(result) <= 8
        # First and last are preserved
        assert result[0] == "msg0"
        assert result[1] == "msg1"
        assert result[-1] == "msg19"
        assert result[-2] == "msg18"
        # Middle messages are from between first and last
        middle = result[2:-2]
        for m in middle:
            idx = int(m.replace("msg", ""))
            assert 2 <= idx <= 17

    def test_truncates_long_messages(self):
        config = SamplingConfig(
            max_total_messages=5,
            max_chars_per_message=10,
        )
        msgs = ["a" * 50, "short"]
        result = sample_messages(msgs, config)
        assert result[0] == "a" * 10 + "..."
        assert result[1] == "short"

    def test_enforces_total_char_budget(self):
        config = SamplingConfig(
            max_total_messages=10,
            max_chars_per_message=1000,
            max_chars_total=25,
        )
        msgs = ["a" * 20, "b" * 20, "c" * 20]
        result = sample_messages(msgs, config)
        total_chars = sum(len(m) for m in result)
        # Budget is 25 chars: first msg (20) + partial second (5+...)
        assert total_chars <= 30  # allow for "..." suffix

    def test_order_preserved(self):
        config = SamplingConfig(
            first_messages=1,
            last_messages=1,
            max_total_messages=5,
        )
        msgs = [f"msg{i:02d}" for i in range(30)]
        result = sample_messages(msgs, config)
        indices = [int(m.replace("msg", "")) for m in result]
        assert indices == sorted(indices)
