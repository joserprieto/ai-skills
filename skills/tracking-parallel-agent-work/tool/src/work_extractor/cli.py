"""CLI entry point for work-extractor."""

from __future__ import annotations

from datetime import date
from pathlib import Path

import click

from work_extractor.config import Config
from work_extractor.extractor import extract_blocks, group_by_day, list_sessions
from work_extractor.formatters import json_fmt, yaml_fmt


@click.group()
@click.option(
    "--config",
    "config_path",
    default=None,
    type=click.Path(exists=True, path_type=Path),
    help="Path to config.yaml (default: bundled)",
)
@click.option(
    "--search-path",
    default=None,
    help="Override JSONL search path pattern",
)
@click.option(
    "--timezone",
    default=None,
    help="Timezone for date interpretation (default: Europe/Madrid)",
)
@click.option(
    "--gap",
    default=None,
    type=int,
    help="Gap threshold in minutes to split blocks (default: 30)",
)
@click.option(
    "--format",
    "output_format",
    type=click.Choice(["yaml", "json"]),
    default=None,
    help="Output format (default: yaml)",
)
@click.pass_context
def main(ctx, config_path, search_path, timezone, gap, output_format):
    """Extract work blocks from AI agent conversation logs."""
    config = Config.load(config_path)
    if search_path:
        config.search_path = search_path
    if timezone:
        config.timezone = timezone
    if gap:
        config.gap_threshold_minutes = gap
    if output_format:
        config.output_format = output_format
    ctx.ensure_object(dict)
    ctx.obj["config"] = config


@main.command()
@click.option("--date", "target_date", required=False, help="Single date (YYYY-MM-DD)")
@click.option("--from", "date_from", required=False, help="Start date (YYYY-MM-DD)")
@click.option("--to", "date_to", required=False, help="End date (YYYY-MM-DD)")
@click.pass_context
def extract(ctx, target_date, date_from, date_to):
    """Extract work blocks for a date or date range."""
    config: Config = ctx.obj["config"]

    if target_date:
        d = date.fromisoformat(target_date)
        d_from, d_to = d, d
    elif date_from and date_to:
        d_from = date.fromisoformat(date_from)
        d_to = date.fromisoformat(date_to)
    elif date_from:
        d_from = date.fromisoformat(date_from)
        d_to = date.today()
    else:
        d_from = d_to = date.today()

    blocks = extract_blocks(config, d_from, d_to)
    days = group_by_day(blocks, config.timezone)

    formatter = yaml_fmt if config.output_format == "yaml" else json_fmt
    click.echo(formatter.format_days(days, config.pricing, config.sampling))


@main.command()
@click.option("--date", "target_date", required=False, help="Date (YYYY-MM-DD), default: today")
@click.pass_context
def sessions(ctx, target_date):
    """List sessions with activity on a given date."""
    config: Config = ctx.obj["config"]
    d = date.fromisoformat(target_date) if target_date else date.today()

    session_list = list_sessions(config, d)

    if not session_list:
        click.echo(f"No sessions found for {d.isoformat()}")
        return

    click.echo(f"Sessions for {d.isoformat()} ({config.timezone}):\n")
    for s in session_list:
        click.echo(f"  {s['start_local'][:16]}  {s['project_path']}")
        click.echo(f"    account={s['account']} profile={s['profile']}")
        click.echo(f"    duration={s['duration_minutes']}min  session={s['session_id'][:8]}...")
        click.echo(f"    \"{s['first_message']}\"")
        click.echo()
