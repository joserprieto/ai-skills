"""Cost estimation from token usage and pricing tables."""

from __future__ import annotations


def estimate_cost(
    model: str,
    input_tokens: int,
    output_tokens: int,
    cache_creation_tokens: int = 0,
    cache_read_tokens: int = 0,
    pricing: dict[str, dict[str, float]] | None = None,
) -> float | None:
    """Estimate cost in USD for a given model and token counts.

    Returns None if pricing is empty or the model is not in the pricing table.
    """
    if not pricing:
        return None
    model_pricing = pricing.get(model)
    if model_pricing is None:
        return None
    return (
        input_tokens * model_pricing["input"]
        + output_tokens * model_pricing["output"]
        + cache_creation_tokens * model_pricing.get("cache_write", model_pricing["input"])
        + cache_read_tokens * model_pricing.get("cache_read", model_pricing["input"])
    ) / 1_000_000
