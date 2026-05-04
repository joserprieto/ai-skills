# CHANGELOG Automation

This project automatically generates `CHANGELOG.md` using
[Keep a Changelog](https://keepachangelog.com/) format.

## How It Works

1. Developers write [Conventional Commits](./commits.md)
2. `commit-and-tag-version` parses commits since the last tag
3. Commits are grouped into sections and written to `CHANGELOG.md`
4. After generation, the CHANGELOG is enriched with descriptive content

## Section Mapping

Conventional Commits are mapped to Keep a Changelog sections:

| Commit Type | CHANGELOG Section |
|-------------|-------------------|
| `feat`      | Features          |
| `fix`       | Bug Fixes         |
| `refactor`  | Code Refactoring  |
| `perf`      | Performance       |
| `security`  | Security          |
| `build`     | Build System      |
| `docs`      | Documentation     |

Hidden by default (maintenance types):

- `style`, `test`, `chore`, `ci`, `revert`

## Templates

Custom Handlebars templates in `.changelog-templates/`:

```
.changelog-templates/
├── template.hbs   # Main structure
├── header.hbs     # Version header with date
├── commit.hbs     # Individual commit format
└── footer.hbs     # Breaking changes section
```

## Enriching the CHANGELOG

The auto-generated CHANGELOG only contains commit subjects. After each release, enrich it with
descriptive content:

```bash
# After make release/minor (or patch/major)
# 1. Edit CHANGELOG.md — add rich descriptions under each section
# 2. Amend the release commit
git add CHANGELOG.md
git commit --amend --no-edit
# 3. Recreate the tag on the amended commit
git tag -d vX.Y.Z
git tag -a vX.Y.Z -m "chore(release): vX.Y.Z"
```

## CHANGELOG Header

**IMPORTANT:** The `CHANGELOG.md` file MUST start empty (no header content). The header is defined
in `config.header` inside `.versionrc.js` and is automatically prepended on every release. If the
file already contains a header, it will be duplicated.

## Configuration

CHANGELOG generation is configured in `.versionrc.js`:

```javascript
module.exports = {
  header: '# Changelog\n\n...',  // Auto-prepended header
  types: [
    { type: 'feat', section: 'Features', hidden: false },
    { type: 'fix', section: 'Bug Fixes', hidden: false },
    // ...
  ],
  writerOpts: {
    mainTemplate: /* .changelog-templates/template.hbs */,
    // ...
  }
};
```

## Best Practices

1. **Write meaningful commit messages** - They become CHANGELOG entries
2. **Use scopes** - They appear in parentheses: `**scope:** description`
3. **Reference issues** - Links are auto-generated: `#42` → `[#42](url)`
4. **Document breaking changes** - Use `BREAKING CHANGE:` in commit footer
5. **Enrich after generation** - Add context that commit subjects alone don't convey

## Related

- [commits.md](./commits.md) - Commit message format
- [versioning.md](./versioning.md) - Version strategy
- [releases.md](./releases.md) - Release workflow
