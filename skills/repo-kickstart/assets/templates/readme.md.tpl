# PROJECT_NAME

[![CI](https://github.com/GITHUB_OWNER/PROJECT_NAME/actions/workflows/ci.yml/badge.svg)](https://github.com/GITHUB_OWNER/PROJECT_NAME/actions/workflows/ci.yml)

PROJECT_DESCRIPTION

## Quick Start

```bash
git clone https://github.com/GITHUB_OWNER/PROJECT_NAME.git
cd PROJECT_NAME
make install
make check/deps
```

## Commands

Run `make help` to see all available commands:

| Command | Description |
| --- | --- |
| `make install` | Install dependencies and configure git hooks |
| `make lint` | Run all linters |
| `make lint/fix` | Auto-fix lint issues |
| `make format` | Format all files |
| `make format/check` | Check formatting without changes |
| `make qa` | Run all quality checks |
| `make release` | Create a release (auto-detect bump) |
| `make release/dry-run` | Preview release without changes |
| `make clean` | Clean temporary files |
| `make help` | Show help message |

## Project Structure

```text
PROJECT_NAME/
├── .github/          # CI workflows, issue templates, scripts
├── .changelog-templates/  # Handlebars templates for CHANGELOG
├── .githooks/        # Git hooks (data leak prevention)
├── CHANGELOG.md      # Auto-generated changelog
├── CONTRIBUTING.md   # Contribution guidelines
├── LICENSE           # Project license
├── Makefile          # Task runner
├── README.md         # This file
├── ROADMAP.md        # Project roadmap
└── SECURITY.md       # Security policy
```

## Development

### Prerequisites

- Node.js >= 20
- shellcheck
- GNU Make
- GitHub CLI (`gh`)

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development setup.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process
for submitting pull requests.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
