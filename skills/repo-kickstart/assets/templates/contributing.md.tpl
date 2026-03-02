# Contributing to PROJECT_NAME

Thank you for your interest in contributing to **PROJECT_NAME**! This guide will help you get
started.

## Prerequisites

- Node.js >= 20
- shellcheck
- GNU Make
- GitHub CLI (`gh`)

## Development Setup

1. Fork the repository
2. Clone your fork:

   ```bash git clone https://github.com/YOUR_USERNAME/PROJECT_NAME.git cd PROJECT_NAME
   ```

3. Install dependencies:

   ```bash make install ```

4. Verify your setup:

   ```bash make check/deps ```

## Workflow

1. Create a feature branch from `main`:

   ```bash git checkout -b feat/your-feature-name ```

2. Make your changes
3. Run quality checks:

   ```bash make qa ```

4. Commit using conventional commit format (see below)
5. Push and open a Pull Request

## Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/). Every commit
message must follow this format:

```text type(optional-scope): description

[optional body]

[optional footer(s)] ```

### Types

| Type       | Description                 |
| ---------- | --------------------------- |
| `feat`     | New feature                 |
| `fix`      | Bug fix                     |
| `docs`     | Documentation only          |
| `style`    | Formatting, no code change  |
| `refactor` | Code restructuring          |
| `test`     | Adding or updating tests    |
| `chore`    | Maintenance tasks           |
| `ci`       | CI/CD changes               |
| `perf`     | Performance improvement     |
| `build`    | Build system changes        |
| `revert`   | Reverting a previous commit |

## Code Quality

Before submitting a PR, ensure all checks pass:

```bash make lint # Run all linters make format/check # Check formatting make qa # Run
all quality checks (lint + format) ```

## Pull Request Checklist

- [ ] Code follows the project's style guidelines
- [ ] All linters pass (`make lint`)
- [ ] Formatting is correct (`make format/check`)
- [ ] Commit messages follow Conventional Commits
- [ ] Documentation is updated (if applicable)

## Release Process

Releases are managed by the maintainers using `make release`. See the [Makefile](Makefile) for
available release commands.
