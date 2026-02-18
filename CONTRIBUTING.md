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

1. Create a directory under `skills/` with the skill name (use hyphens)
2. Add a `SKILL.md` file with YAML frontmatter (`name` and `description`)
3. Follow the structure in the existing skills for reference
4. Ensure the skill passes markdown linting

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
feat(skills): add enterprise-repo-setup skill
fix(skills): correct shellcheck severity flag in enterprise-repo-setup
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
