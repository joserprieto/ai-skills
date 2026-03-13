#!/usr/bin/env python3
"""Process work-extractor JSON into TIL daily tracking blocks.

Converts raw work-extractor output (JSON) into formatted markdown blocks
compatible with the TIL daily time-tracking system. Handles:

- UTC → local timezone conversion
- Project path → work context mapping (prefix matching)
- TIL sub-context inference from user messages
- Overlap detection between concurrent sessions
- 3-metric calculation (throughput, wall-clock, parallelism factor)
- Period grouping (madrugada/mañana/tarde/noche)

Usage:
    python process_blocks.py <extraction.json> [--format blocks|metrics|full]

The input JSON is the output of `work-extractor --format json extract --date YYYY-MM-DD`.
"""
import json
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

CET = ZoneInfo("Europe/Madrid")

# Context mapping (longest prefix first)
# Each entry: (path_prefix, context_label, display_name)
CONTEXT_MAP = [
    ("/Users/joserprieto/Projects/joserprieto/technical-insight-lab/contexts/avincis", "job/avincis", "Avincis"),
    ("/Users/joserprieto/Projects/joserprieto/encaje-ai", "job/avincis/encaje-ai", "Encaje AI"),
    ("/Users/joserprieto/Projects/Avincis/joserprieto/efx-iam-provisioning", "job/avincis/efx-iam-provisioning", "efx-iam-provisioning"),
    ("/Users/joserprieto/Projects/joserprieto/azure-infrastructure", "job/avincis/azure-infra", "Azure Infrastructure"),
    ("/Users/joserprieto/Projects/joserprieto/ansible-security-audit", "job/avincis/ansible-security-audit", "ansible-security-audit"),
    ("/Users/joserprieto/Projects/joserprieto/personal-site", "personal/personal-site", "Personal Site"),
    ("/Users/joserprieto/Projects/joserprieto/professional-reawakening", "personal/professional-reawakening", "Professional Reawakening"),
    ("/Users/joserprieto/Projects/joserprieto/ai-skills", "personal/ai-skills", "AI Skills"),
    ("/Users/joserprieto/Projects/joserprieto/ai-engineering-patterns", "personal/ai-engineering-patterns", "AI Engineering Patterns"),
    ("/Users/joserprieto/Projects/joserprieto/ai-diagrams-toolkit", "personal/ai-diagrams-toolkit", "AI Diagrams Toolkit"),
    ("/Users/joserprieto/Projects/joserprieto/mdforge", "personal/mdforge", "mdforge"),
    ("/Users/joserprieto/Projects/joserprieto/attorneys-office-digital-efficiency", "cuatro-digital/attorneys-office", "Attorneys Office"),
    ("/Users/joserprieto/Projects/joserprieto/technical-insight-lab", "personal/til", "TIL"),
    ("/Users/joserprieto/Projects/joserprieto", "personal", "Personal"),
]
# Sort by path length descending for correct prefix matching
CONTEXT_MAP.sort(key=lambda x: len(x[0]), reverse=True)


def map_context(project_path):
    """Map a filesystem path to a (context, label) tuple via prefix matching."""
    for prefix, ctx, label in CONTEXT_MAP:
        if project_path.startswith(prefix):
            return ctx, label
    return "unknown", "Unknown"


def utc_to_local(utc_str):
    """Convert a UTC ISO timestamp string to local (Europe/Madrid) datetime."""
    dt = datetime.fromisoformat(utc_str.replace("Z", "+00:00"))
    return dt.astimezone(CET)


def fmt_duration(mins):
    """Format minutes as 'Xh Xmin' or 'Xmin'."""
    if mins < 1:
        return "~1min"
    h, m = divmod(int(mins), 60)
    if h == 0:
        return f"{m}min"
    return f"{h}h {m}min"


def fmt_time(dt):
    """Format datetime as HH:MM."""
    return dt.strftime("%H:%M")


def synthesize_activities(block):
    """Generate concise activity bullets from user_messages_sample."""
    samples = block.get("user_messages_sample", [])
    if not samples:
        samples = [block.get("first_user_message", "")]

    activities = []
    for s in samples[:5]:
        s = s.replace("\n", " ").strip()
        if len(s) > 150:
            s = s[:147] + "..."
        # Skip system/command messages
        if s and not s.startswith("<command") and not s.startswith("<task-notification"):
            activities.append(s)

    # Deduplicate by prefix
    seen = set()
    unique = []
    for a in activities:
        key = a[:50]
        if key not in seen:
            seen.add(key)
            unique.append(a)

    return unique[:4]


def detect_overlaps(blocks_cet):
    """Detect overlapping blocks.

    Args:
        blocks_cet: list of (start_dt, end_dt, block_data) tuples

    Returns:
        dict of block_idx -> list of (other_idx, overlap_minutes)
    """
    overlaps = {}
    for i, (start_i, end_i, _) in enumerate(blocks_cet):
        for j, (start_j, end_j, _) in enumerate(blocks_cet):
            if i >= j:
                continue
            overlap_start = max(start_i, start_j)
            overlap_end = min(end_i, end_j)
            if overlap_start < overlap_end:
                overlap_mins = (overlap_end - overlap_start).total_seconds() / 60
                if overlap_mins >= 1:
                    overlaps.setdefault(i, []).append((j, int(overlap_mins)))
                    overlaps.setdefault(j, []).append((i, int(overlap_mins)))
    return overlaps


def infer_til_context(block):
    """For TIL-rooted blocks, infer specific sub-context from message content.

    When the project_path points to the TIL root, the cwd alone doesn't tell us
    what was worked on. We use user_messages_sample to infer the actual context.
    """
    samples = block.get("user_messages_sample", [])
    first = block.get("first_user_message", "")
    all_text = " ".join(samples + [first]).lower()

    # Ordered from most specific to least specific
    rules = [
        (["cesga34", "cryptojacking", "monero"], "job/avincis/einforex/incidents", "CESGA34 Cryptojacking Incident"),
        (["efx-iam", "einforex-iam", "iam-provisioning", "keycloak"], "job/avincis/efx-iam-provisioning", "efx-iam-provisioning"),
        (["access-governance", "gobernanza"], "job/avincis/efx-access-governance", "efx-access-governance"),
        (["govops", "saas"], "personal/govops-saas", "GovOps SaaS"),
        (["agentsboard", "agents-board", "agents board"], "personal/agents-board", "AgentsBoard"),
        (["ansible", "security"], "job/avincis/ansible-security-audit", "ansible-security-audit"),
        (["work-extractor"], "personal/ai-skills", "AI Skills (work-extractor)"),
        (["time track", "time-track", "daily track"], "personal/til/control-hub", "Time Tracking"),
        (["brand", "showcase"], "personal/personal-site", "Brand Showcase"),
        (["jrp-ui", "design-system", "design system"], "personal/personal-site", "jrp-ui / Design System"),
        (["career"], "personal/personal-site", "CareerExplorer"),
        (["professional-reawakening", "professional reawakening"], "personal/professional-reawakening", "Professional Reawakening"),
        (["personal-site", "astro"], "personal/personal-site", "Personal Site"),
        ([".ssh", "ssh config"], "job/avincis/einforex", "SSH config"),
    ]

    for keywords, ctx, label in rules:
        if any(kw in all_text for kw in keywords):
            return ctx, label

    # Check compound rules
    if "azure" in all_text and ("migrate" in all_text or "assess" in all_text):
        return "job/avincis/einforex/azure-migration", "Azure Migrate Assessment"
    if "plan" in all_text and ("briefing" in all_text or "presentation" in all_text):
        return "job/avincis/einforex/incidents", "Incident Briefing"
    if "meet" in all_text and ("johan" in all_text or "incidente" in all_text):
        return "job/avincis/einforex", "Meeting follow-up"

    return "personal/til", "TIL (general)"


def generate_block_md(block, idx, overlaps, all_blocks):
    """Generate TIL-format markdown for a single work block."""
    start_cet = utc_to_local(block["start_utc"])
    end_cet = utc_to_local(block["end_utc"])
    dur = block["duration_minutes"]

    ctx, label = map_context(block["project_path"])
    if ctx == "personal/til":
        ctx, label = infer_til_context(block)

    activities = synthesize_activities(block)

    lines = []
    lines.append(f"#### [{fmt_time(start_cet)}-{fmt_time(end_cet)}] {label} ({fmt_duration(dur)})")
    lines.append(f"- **Contexto**: {ctx}")
    lines.append(f"- **Planificado**: sí")
    lines.append(f"- **Estado**: 🔄 en-progreso")

    if activities:
        lines.append(f"- **Actividad/Actividades**:")
        for a in activities:
            lines.append(f"  - {a}")

    if idx in overlaps:
        for other_idx, overlap_mins in overlaps[idx]:
            other = all_blocks[other_idx]
            other_ctx, other_label = map_context(other["project_path"])
            if other_ctx == "personal/til":
                _, other_label = infer_til_context(other)
            other_start = utc_to_local(other["start_utc"])
            other_end = utc_to_local(other["end_utc"])
            lines.append(f"- **Solapamiento**: paralelo a {other_label} ({fmt_time(other_start)}-{fmt_time(other_end)}) — ~{overlap_mins}min overlap")

    return "\n".join(lines)


def calc_metrics(blocks):
    """Calculate the 3-metric model from a list of blocks.

    Returns:
        (ctx_throughput, total_throughput, wall_clock, factor)
    """
    ctx_throughput = {}
    for b in blocks:
        ctx, label = map_context(b["project_path"])
        if ctx == "personal/til":
            ctx, label = infer_til_context(b)

        if ctx.startswith("job/avincis"):
            top = "Avincis"
        elif ctx.startswith("personal"):
            top = "Personal"
        elif ctx.startswith("cuatro-digital"):
            top = "Cuatro Digital"
        else:
            top = "Otros"

        ctx_throughput.setdefault(top, {})
        ctx_throughput[top].setdefault(label, 0)
        ctx_throughput[top][label] += b["duration_minutes"]

    total_throughput = sum(b["duration_minutes"] for b in blocks)

    # Wall-clock: union of all intervals
    intervals = []
    for b in blocks:
        start = utc_to_local(b["start_utc"])
        end = utc_to_local(b["end_utc"])
        if start < end:
            intervals.append((start, end))

    if not intervals:
        return ctx_throughput, total_throughput, 0, 1.0

    intervals.sort()
    merged = [intervals[0]]
    for s, e in intervals[1:]:
        if s <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], e))
        else:
            merged.append((s, e))

    wall_clock = sum((e - s).total_seconds() / 60 for s, e in merged)
    factor = total_throughput / wall_clock if wall_clock > 0 else 1.0

    return ctx_throughput, total_throughput, wall_clock, factor


def format_metrics(ctx_throughput, total_throughput, wall_clock, factor, blocks):
    """Format 3-metric summary as TIL markdown."""
    lines = []
    lines.append("- **Throughput por contexto**:")

    for top in sorted(ctx_throughput.keys()):
        top_total = sum(ctx_throughput[top].values())
        lines.append(f"  - {top}: {fmt_duration(top_total)}")
        for proj, mins in sorted(ctx_throughput[top].items(), key=lambda x: -x[1]):
            lines.append(f"    - _{proj}_: {fmt_duration(mins)}")

    lines.append(f"  - _Total throughput_: {fmt_duration(total_throughput)}")

    if factor > 1.05:
        starts = [utc_to_local(b["start_utc"]) for b in blocks]
        ends = [utc_to_local(b["end_utc"]) for b in blocks]
        first = min(starts)
        last = max(ends)
        lines.append(f"- **Tiempo reloj**: {fmt_duration(wall_clock)} ({fmt_time(first)}→{fmt_time(last)}, con pausas)")
        lines.append(f"- **Factor paralelismo**: ×{factor:.2f}")

    return "\n".join(lines)


def process_day(json_path):
    """Process a single day's extraction data into structured output."""
    with open(json_path) as f:
        data = json.load(f)

    if not data:
        return None

    day = data[0]
    blocks = [b for b in day["blocks"] if b["duration_minutes"] > 0]

    if not blocks:
        return None

    blocks.sort(key=lambda b: b["start_utc"])

    blocks_cet = [(utc_to_local(b["start_utc"]), utc_to_local(b["end_utc"]), b) for b in blocks]
    overlaps = detect_overlaps(blocks_cet)

    block_mds = []
    for i, b in enumerate(blocks):
        md = generate_block_md(b, i, overlaps, blocks)
        block_mds.append((utc_to_local(b["start_utc"]), md))

    ctx_throughput, total_throughput, wall_clock, factor = calc_metrics(blocks)
    metrics_md = format_metrics(ctx_throughput, total_throughput, wall_clock, factor, blocks)

    # Group blocks by period
    periods = {"madrugada": [], "manana": [], "tarde": [], "noche": []}
    for start_cet, md in block_mds:
        h = start_cet.hour
        if h < 7:
            periods["madrugada"].append(md)
        elif h < 14:
            periods["manana"].append(md)
        elif h < 21:
            periods["tarde"].append(md)
        else:
            periods["noche"].append(md)

    return {
        "date": day["date"],
        **periods,
        "metrics": metrics_md,
        "total_blocks": len(blocks),
        "total_throughput": total_throughput,
        "wall_clock": wall_clock,
        "factor": factor,
        "cost": day.get("estimated_cost_usd", 0),
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: process_blocks.py <extraction.json> [--format blocks|metrics|full]")
        sys.exit(1)

    path = sys.argv[1]
    output_format = "full"
    if "--format" in sys.argv:
        idx = sys.argv.index("--format")
        if idx + 1 < len(sys.argv):
            output_format = sys.argv[idx + 1]

    result = process_day(path)
    if not result:
        print("No blocks found.")
        sys.exit(0)

    if output_format in ("full", "blocks"):
        print(f"=== {result['date']} ===")
        print(f"Blocks: {result['total_blocks']}, Throughput: {fmt_duration(result['total_throughput'])}, Factor: ×{result['factor']:.2f}, Cost: ${result['cost']:.2f}")
        print()
        for period_name, period_key in [("MADRUGADA", "madrugada"), ("MAÑANA", "manana"), ("TARDE", "tarde"), ("NOCHE", "noche")]:
            if result[period_key]:
                print(f"### {period_name}:")
                for md in result[period_key]:
                    print(md)
                    print()

    if output_format in ("full", "metrics"):
        print("### MÉTRICAS:")
        print(result["metrics"])


if __name__ == "__main__":
    main()
