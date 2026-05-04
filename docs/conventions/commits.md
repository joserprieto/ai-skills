# Conventional Commits

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) specification
for commit messages.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

## Types

| Type       | Description                   | CHANGELOG Section |
| ---------- | ----------------------------- | ----------------- |
| `feat`     | New feature                   | Features          |
| `fix`      | Bug fix                       | Bug Fixes         |
| `refactor` | Code refactoring              | Code Refactoring  |
| `perf`     | Performance improvement       | Performance       |
| `docs`     | Documentation only            | Documentation     |
| `style`    | Code style (formatting, etc.) | (hidden)          |
| `test`     | Adding/updating tests         | (hidden)          |
| `chore`    | Maintenance tasks             | (hidden)          |
| `ci`       | CI/CD changes                 | (hidden)          |
| `build`    | Build system changes          | Build System      |
| `revert`   | Revert a commit               | Reverts           |
| `security` | Security fixes                | Security          |

## Scopes

For this repo (collection of skills), scopes follow two patterns:

**Per-skill scope** — when the change targets a specific skill, the scope is the skill's directory
name (matches the `name` field in its frontmatter):

- `feat(huly-api): v0.1.0 — initial release`
- `fix(drawio-uml-shapes): v0.5.1 — warn about mxGeometry requirement`
- `feat(repo-kickstart): v0.7.1 — optional workflows + gitignore fix`

The skill version (from `metadata.version` in the frontmatter) is included in the subject line after
the type+scope, so commit history shows skill version progression at a glance.

**Repo-wide scopes** — for changes that touch infrastructure rather than a single skill:

- `ci` — GitHub Actions workflows, scripts under `.github/scripts/`
- `conventions` — documents under `docs/conventions/`
- `proposals` — documents under `docs/proposals/`
- `skills-index` — the auto-generated index in README.md and its tooling
- `deps` — Dependencies (npm, scaffold templates)

## Examples

### Feature

```
feat(api): add user authentication endpoint

Implement JWT-based authentication with refresh tokens.
```

### Bug fix

```
fix(core): correct date parsing for ISO 8601 format

Dates with timezone offset were being parsed incorrectly.

Closes #42
```

### Breaking change

```
feat(api)!: change response format to JSON:API

BREAKING CHANGE: All API endpoints now return JSON:API
formatted responses instead of plain JSON objects.
```

## Commit Message Guidelines

1. **Subject line**: Max 72 characters, imperative mood ("add" not "added")
2. **Body**: Wrap at 72 characters, explain what and why
3. **Footer**: Reference issues, note breaking changes

## Tooling

We use `commit-and-tag-version` to:

- Parse commit messages
- Generate CHANGELOG.md
- Bump version in `.semver`
- Create git tags

See [releases.md](./releases.md) for release workflow.
