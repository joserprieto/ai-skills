# Development Workflow

Basic development workflow for contributors.

## First-Time Setup

```bash
# Clone the repository
git clone <repo-url>
cd <project>

# Verify dependencies
make check/deps

# Install tooling + configure git hooks
make install
```

## Daily Workflow

### 1. Create a Branch

```bash
git checkout -b feat/short-description
# or: fix/short-description, refactor/short-description
```

Branch naming follows the commit type prefix for consistency.

### 2. Develop

Write code following the project conventions:

- **TDD**: Write failing test first, then implement, then refactor (see [testing.md](./testing.md))
- **Commits**: Use [Conventional Commits](./commits.md) format
- **Small commits**: Each commit should be a single logical change

### 3. Quality Checks

Before pushing, run the full quality suite:

```bash
make qa          # Lint + format check
make test        # Run test suite (if configured)
```

Fix any issues:

```bash
make lint/fix    # Auto-fix lint issues
make format      # Auto-fix formatting
```

### 4. Push and PR

```bash
git push -u origin feat/short-description
```

Create a Pull Request following the PR template.

### 5. After Merge

Releases are created from `main` by maintainers using `make release/*`. See
[releases.md](./releases.md).

## Git Hooks

The `.githooks/pre-commit` hook runs automatically on every commit:

- Scans for personal data leaks (emails, API keys, credentials)
- Blocks commits containing sensitive patterns

Git hooks are configured during `make install` via:

```bash
git config core.hooksPath .githooks
```

## Empty Directories in Git

Git does not track empty directories. To preserve directory structure, use a `.gitignore` file
inside the empty directory — **never** `.gitkeep` or `.empty`:

```gitignore
# Keep this directory tracked but ignore its contents
*
!.gitignore
```

**Why `.gitignore` over `.gitkeep`/`.empty`:**

- `.gitignore` is a **standard git mechanism**; `.gitkeep`/`.empty` are informal conventions with no
  special meaning to git
- When the directory later needs to track content, you **modify** the `.gitignore` rules — a
  natural, incremental change
- With `.gitkeep`, you must remember to delete it when adding real files, and stale `.gitkeep` files
  accumulate silently across the project
- `.gitignore` also **protects against accidental commits** — sensitive files dropped into the
  directory won't be staged

## Editor Setup

The `.editorconfig` file ensures consistent formatting across editors:

- UTF-8 encoding
- LF line endings
- Trailing whitespace trimmed
- Final newline inserted

Most editors support EditorConfig natively or via plugin.

## Related

- [commits.md](./commits.md) - Commit message format
- [testing.md](./testing.md) - Testing approach
- [build-tools.md](./build-tools.md) - Available make targets
