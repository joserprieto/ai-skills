# Build Tools

All developer operations go through the `Makefile`. This is the project's command center — a single
entry point for linting, formatting, testing, releasing, and dependency management.

## Why Make

- **Universal**: Available on every Unix system, no runtime dependencies
- **Declarative**: Target dependencies are explicit
- **Discoverable**: `make help` lists all available commands
- **Composable**: Complex workflows built from simple targets

## Target Naming Convention

Targets follow a `verb/noun` pattern:

```
lint/md          # Lint markdown files
lint/shell       # Lint shell scripts
lint/md/fix      # Auto-fix markdown lint issues
format/check     # Check formatting
release/patch    # Create patch release
release/first    # Create first release
```

This convention keeps targets discoverable and avoids ambiguity.

## Available Targets

### Dependency Management

```bash
make check/deps    # Verify all required tools are installed
make install       # Install project dependencies + configure git hooks
```

### Linting

```bash
make lint          # Run all linters
make lint/md       # Lint markdown files only
make lint/shell    # Lint shell scripts only (shellcheck)
make lint/fix      # Auto-fix all lint issues
make lint/md/fix   # Auto-fix markdown only
```

### Formatting

```bash
make format        # Format all files (markdown, JSON, YAML)
make format/check  # Check formatting without changes
```

### Quality Assurance

```bash
make qa            # Run all quality checks (lint + format check)
```

`qa` is the gate for all releases — if anything fails, the release aborts.

### Releases

```bash
make release/dry-run   # Preview release without changes
make release           # Auto-detect bump from commits
make release/patch     # Bug fix release
make release/minor     # Feature release
make release/major     # Breaking change release
make release/first     # Initial release (0.0.0 → 0.1.0)
```

See [releases.md](./releases.md) for the complete release workflow.

### Cleanup

```bash
make clean         # Remove temporary files (node_modules, etc.)
```

## Adding New Targets

1. Add the target with a `##` comment (auto-appears in `make help`):

   ```makefile
   .PHONY: test/unit
   test/unit: ## Run unit tests
       @pytest tests/unit/ -v
   ```

2. For composite targets, add as dependency:

   ```makefile
   .PHONY: test
   test: test/unit test/integration ## Run all tests
   ```

## RELEASE_FILES

The `RELEASE_FILES` variable lists all files that get staged during a release commit. It MUST
include every file listed in `bumpFiles` in `.versionrc.js`:

```makefile
RELEASE_FILES := CHANGELOG.md .semver Makefile
# Add pyproject.toml here if it's in bumpFiles
```

## Related

- [releases.md](./releases.md) - Release workflow
- [versioning.md](./versioning.md) - Version strategy
