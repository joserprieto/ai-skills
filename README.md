# AI Skills

[![CI](https://github.com/joserprieto/ai-skills/actions/workflows/ci.yml/badge.svg)](https://github.com/joserprieto/ai-skills/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Reusable AI agent skills for Claude Code and other AI tools** — a versioned collection of
battle-tested skills, patterns, and automation templates.

**[Roadmap](ROADMAP.md)** | **[Contributing](CONTRIBUTING.md)** | **[Changelog](CHANGELOG.md)**

## Overview

AI Skills is a curated collection of reusable skills for AI coding agents. Each skill is a
self-contained reference guide with triggers, workflows, patterns, and common mistakes — designed to
be auto-loaded by Claude Code based on context matching.

All skills follow the [Agent Skills](https://agentskills.io/) open specification
([spec](https://agentskills.io/specification) | [repo](https://github.com/agentskills/agentskills))
— a portable format supported by Claude Code, Cursor, Gemini CLI, VS Code, and
[many other tools](https://agentskills.io/home).

## Available Skills

<!-- BEGIN AUTO-GENERATED SKILLS TABLE - DO NOT EDIT BELOW -->

| Skill                                                                        | Version | Summary                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [contract-first-clean-arch](skills/contract-first-clean-arch/SKILL.md)       | `0.3.0` | Use when starting a new backend or fullstack project, evaluating an existing project's architecture, migrating from code-first to contract-first, introducing Clean Architecture layers, setting up a type generation pipeline, or assessing architectural maturity. |
| [drawio-uml-shapes](skills/drawio-uml-shapes/SKILL.md)                       | `0.5.1` | Use when generating or editing draw.io diagrams with UML shapes.                                                                                                                                                                                                     |
| [expert-panel](skills/expert-panel/SKILL.md)                                 | `0.1.0` | Evaluate any artifact (document, architecture, infrastructure design, domain model, code, PR, proposal) using an independent panel of LLM agent evaluators.                                                                                                          |
| [huly-api](skills/huly-api/SKILL.md)                                         | `0.1.2` | Interact with Huly project management platform via its TypeScript/WebSocket API.                                                                                                                                                                                     |
| [makefile-service-conventions](skills/makefile-service-conventions/SKILL.md) | `0.3.0` | Use when creating or editing a Makefile that orchestrates long-running local services (dev servers, preview servers, build+serve workflows).                                                                                                                         |
| [portless-service-integration](skills/portless-service-integration/SKILL.md) | `0.2.1` | Use when wiring a local development service (dev server, preview server, static site, any long-running HTTP upstream) to portless so it gets a stable `.localhost` URL instead of a port number.                                                                     |
| [repo-kickstart](skills/repo-kickstart/SKILL.md)                             | `0.7.2` | Use when creating a new repository, initializing a project from scratch, or setting up OSS infrastructure (CI/CD, linting, releases, docs).                                                                                                                          |
| [service-manager](skills/service-manager/SKILL.md)                           | `0.3.0` | Use when adding background service management to a project that runs dev servers, preview servers, or any long-running processes.                                                                                                                                    |
| [validating-skills](skills/validating-skills/SKILL.md)                       | `0.1.0` | Use when validating, auditing, or reviewing Agent Skills for compliance with the agentskills.io specification.                                                                                                                                                       |

<!-- END AUTO-GENERATED SKILLS TABLE -->

> _Table auto-generated from each skill's frontmatter. To add or modify a skill, see
> [docs/conventions/skills-index.md](docs/conventions/skills-index.md)._

## Quick Start

```bash
# Clone
git clone https://github.com/joserprieto/ai-skills.git
cd ai-skills

# Install tooling (Node.js required for linting and releases)
npm install

# Verify setup
make check/deps
```

### Using a Skill

1. Copy the skill directory into your Claude Code skills path:

   ```bash
   cp -r skills/repo-kickstart ~/.claude/skills/
   ```

2. The skill's `description` field triggers auto-loading when the conversation matches.

## Commands

| Command                | Description                         |
| ---------------------- | ----------------------------------- |
| `make help`            | Show all available commands         |
| `make check/deps`      | Verify dependencies                 |
| `make lint`            | Run all linters (markdown, shell)   |
| `make lint/fix`        | Auto-fix lint issues where possible |
| `make lint/md`         | Lint markdown files                 |
| `make lint/md/fix`     | Fix markdown lint issues            |
| `make lint/shell`      | Lint shell scripts (shellcheck)     |
| `make format`          | Format markdown and config files    |
| `make format/check`    | Check formatting without changes    |
| `make release/dry-run` | Preview release                     |
| `make release/patch`   | Create patch release                |
| `make release/minor`   | Create minor release                |
| `make release/major`   | Create major release                |

## Project Structure

```
ai-skills/
├── skills/                 # Reusable AI agent skills
│   └── repo-kickstart/
│       └── SKILL.md        # Skill definition
├── .github/                # CI/CD workflows, issue templates, automation scripts
│   ├── workflows/          # GitHub Actions (CI, label sync)
│   ├── scripts/            # CI automation (issue create/close on failure/success)
│   └── config/             # Labels configuration
├── .changelog-templates/   # Handlebars templates for auto-generated changelog
├── Makefile                # Project orchestration
├── README.md               # This file
├── CHANGELOG.md            # Auto-generated from conventional commits
├── ROADMAP.md              # Planned features and milestones
├── CONTRIBUTING.md         # Contribution guidelines
├── SECURITY.md             # Security policy
├── CODE_OF_CONDUCT.md      # Community standards
└── LICENSE                 # MIT License
```

## Development

### Prerequisites

- **Node.js 20+** — For linting and release tooling
- **shellcheck** — For shell script linting (`brew install shellcheck`)
- **GNU Make** — Build orchestration

### Code Quality

All contributions must pass:

- **Markdown lint** — [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) with
  auto-fix
- **Shell lint** — [shellcheck](https://www.shellcheck.net/) for all `.sh` scripts
- **Prettier** — Formatting for markdown, JSON, YAML
- **Conventional Commits** — Enforced via [gitlint](https://jorisroovers.com/gitlint/)

### Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`, `build`, `revert`

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting PRs.

## License

MIT License — see [LICENSE](LICENSE) for details.
