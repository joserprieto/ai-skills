"""Tests for Claude Code JSONL parser."""

from pathlib import Path

from work_extractor.parsers.claude_code import (
    extract_tool_names,
    extract_user_text,
    parse_session,
)

FIXTURES_DIR = Path(__file__).parent / "fixtures"


class TestExtractUserText:
    def test_string_content(self):
        assert extract_user_text("hello world") == "hello world"

    def test_tool_result_returns_none(self):
        content = [{"type": "tool_result", "content": "result", "is_error": False}]
        assert extract_user_text(content) is None

    def test_text_in_array(self):
        content = [{"type": "text", "text": "user message"}]
        assert extract_user_text(content) == "user message"

    def test_empty_string(self):
        assert extract_user_text("   ") == ""


class TestExtractToolNames:
    def test_single_tool(self):
        content = [{"type": "tool_use", "name": "Read", "input": {}}]
        assert extract_tool_names(content) == ["Read"]

    def test_multiple_tools(self):
        content = [
            {"type": "tool_use", "name": "Read", "input": {}},
            {"type": "text", "text": "some text"},
            {"type": "tool_use", "name": "Edit", "input": {}},
        ]
        assert extract_tool_names(content) == ["Read", "Edit"]

    def test_no_tools(self):
        content = [{"type": "text", "text": "just text"}]
        assert extract_tool_names(content) == []


class TestParseSession:
    def test_sample_session_with_matching_path(self, tmp_path):
        """Test with a path that matches the expected pattern."""
        project_dir = (
            tmp_path
            / "accounts"
            / "test-account"
            / "profiles"
            / "standard"
            / "projects"
            / "-Users-testuser-Projects-test-project"
        )
        project_dir.mkdir(parents=True)
        jsonl_file = project_dir / "test-session-001.jsonl"

        fixture = FIXTURES_DIR / "sample_session.jsonl"
        jsonl_file.write_text(fixture.read_text())

        blocks = parse_session(jsonl_file, gap_threshold_minutes=30)

        assert len(blocks) == 2

        # First block: 10:00 to 10:31 (31 min)
        assert blocks[0].first_user_message == "Start working on the feature"
        assert blocks[0].duration_minutes == 31
        assert blocks[0].message_count["user"] == 3
        assert blocks[0].message_count["assistant"] == 3
        assert "Read" in blocks[0].tools_used
        assert "Edit" in blocks[0].tools_used
        assert blocks[0].model == "claude-sonnet-4-6"
        assert blocks[0].account == "test-account"
        assert blocks[0].profile == "standard"
        # project_path comes from `cwd` field in JSONL entries
        assert blocks[0].project_path == "/Users/testuser/Projects/test-project"
        # Token usage: 3 assistant messages with usage fields (no cache in fixture)
        # resp-001: input=100, output=50; resp-002: input=200, output=100; resp-003: input=50, output=20
        assert blocks[0].token_usage["input"] == 350
        assert blocks[0].token_usage["output"] == 170
        assert blocks[0].token_usage["cache_creation"] == 0
        assert blocks[0].token_usage["cache_read"] == 0
        assert blocks[0].total_tokens == 520
        # User messages: "Start working on the feature" and "looks good, thanks"
        # (tool_result message is excluded)
        assert len(blocks[0].user_messages) == 2
        assert blocks[0].user_messages[0] == "Start working on the feature"
        assert blocks[0].user_messages[1] == "looks good, thanks"

        # Second block: 12:30 to 13:00 (30 min)
        assert blocks[1].first_user_message == "Now let's work on the second part"
        assert blocks[1].duration_minutes == 30
        assert "Bash" in blocks[1].tools_used
        # resp-004: input=150, output=80
        assert blocks[1].token_usage["input"] == 150
        assert blocks[1].token_usage["output"] == 80
        # User messages: "Now let's work on the second part" and "done for today"
        assert len(blocks[1].user_messages) == 2
        assert blocks[1].user_messages[0] == "Now let's work on the second part"
        assert blocks[1].user_messages[1] == "done for today"

    def test_no_match_returns_empty(self, tmp_path):
        """A path that doesn't match the pattern returns no blocks."""
        jsonl_file = tmp_path / "random.jsonl"
        fixture = FIXTURES_DIR / "sample_session.jsonl"
        jsonl_file.write_text(fixture.read_text())

        blocks = parse_session(jsonl_file)
        assert blocks == []
