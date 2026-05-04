# Contributing to AI Skills

Thank you for your interest in contributing! This guide will help you get started.

## Prerequisites

- **Node.js 20+** — Required for linting and releases
- **shellcheck** — Shell script linting (`brew install shellcheck`)
- **GNU Make** — Build orchestration

## Development Setup

```bash
# Clone and install
git clone https://github.com/joserprieto/ai-skills.git
cd ai-skills
npm install

# Verify setup
make check/deps
```

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Run `make lint` to check for issues
4. Run `make lint/fix` to auto-fix where possible
5. Commit using Conventional Commits
6. Open a Pull Request

## Adding a New Skill

1. Create a directory under `skills/` with the skill name (use hyphens).
2. Add a `SKILL.md` file with YAML frontmatter (`name`, `description`, and `metadata.version`).
3. Run `make skills/index` so the README table picks it up.
4. Stage both `skills/<name>/SKILL.md` and the updated `README.md`, commit and push.

The pre-commit hook and CI both verify the README is in sync. See
[docs/conventions/skills-index.md](docs/conventions/skills-index.md) for the full flow,
[docs/conventions/versioning.md](docs/conventions/versioning.md) for the per-skill SemVer model, and
[docs/conventions/commits.md](docs/conventions/commits.md) for how to write the commit subject.

## Project Conventions

The repo's working conventions live under [docs/conventions/](docs/conventions/):

- [build-tools.md](docs/conventions/build-tools.md) — Make targets and shell tooling
- [cicd.md](docs/conventions/cicd.md) — CI pipeline structure
- [changelog.md](docs/conventions/changelog.md) — CHANGELOG generation (Flow 2 releases)
- [commits.md](docs/conventions/commits.md) — Conventional Commits + per-skill scopes
- [dev-workflow.md](docs/conventions/dev-workflow.md) — Day-to-day workflow
- [releases.md](docs/conventions/releases.md) — Per-skill and repo release flows
- [skill-ownership.md](docs/conventions/skill-ownership.md) — Trigger ownership when skills overlap
- [skills-index.md](docs/conventions/skills-index.md) — Auto-generated README table
- [versioning.md](docs/conventions/versioning.md) — Dual SemVer (repo + per-skill)

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type       | Description                             |
| ---------- | --------------------------------------- |
| `feat`     | New feature (new skill, new section)    |
| `fix`      | Bug fix (skill correction)              |
| `docs`     | Documentation only                      |
| `style`    | Formatting, no content change           |
| `refactor` | Restructuring without changing behavior |
| `perf`     | Performance improvement                 |
| `test`     | Adding or correcting tests              |
| `build`    | Build system or dependencies            |
| `ci`       | CI configuration                        |
| `chore`    | Other changes (maintenance)             |

### Examples

```text
feat(skills): add repo-kickstart skill
fix(skills): correct shellcheck severity flag in repo-kickstart
docs(readme): update installation steps
ci(workflow): add shell linting job
```

## Code Quality

```bash
make lint            # Run all linters
make lint/fix        # Auto-fix lint issues
make lint/md         # Lint markdown only
make lint/md/fix     # Fix markdown issues
make lint/shell      # Lint shell scripts
make format          # Format files with prettier
make format/check    # Check formatting without changes
```

### Linting Standards

| Target          | Tool              | Auto-fix     |
| --------------- | ----------------- | ------------ |
| Markdown        | markdownlint-cli2 | Yes          |
| Shell scripts   | shellcheck        | No (manual)  |
| JSON, YAML      | prettier          | Yes          |
| Commit messages | gitlint           | No (rewrite) |

## Pull Request Checklist

- [ ] All linters pass (`make lint`)
- [ ] Formatting is correct (`make format/check`)
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] Documentation updated if this is a user-facing change

## Release Process

Releases are managed via `commit-and-tag-version`:

```bash
make release/dry-run  # Preview what would happen
make release/patch    # 0.1.0 -> 0.1.1
make release/minor    # 0.1.0 -> 0.2.0
make release/major    # 0.1.0 -> 1.0.0
```
