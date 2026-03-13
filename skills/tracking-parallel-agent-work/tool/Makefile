.PHONY: install test extract sessions lint

install:
	uv sync

test:
	uv run pytest -v

extract:
	uv run work-extractor extract --date $(DATE)

extract-range:
	uv run work-extractor extract --from $(FROM) --to $(TO)

sessions:
	uv run work-extractor sessions --date $(DATE)

lint:
	uv run ruff check src/ tests/
	uv run ruff format --check src/ tests/

format:
	uv run ruff format src/ tests/
