# Release Workflow

This document describes the release process for the project.

## Prerequisites

- Clean working directory (`git status` shows no changes)
- All quality checks passing (`make qa`)
- On `main` branch

## Quick Reference

```bash
# Show current version
cat .semver

# Dry-run (preview changes)
make release/dry-run

# Release types
make release/patch     # Bug fixes (0.1.0 → 0.1.1)
make release/minor     # New features (0.1.0 → 0.2.0)
make release/major     # Breaking changes (0.1.0 → 1.0.0)

# First release (0.0.0 → 0.1.0)
make release/first

# Push release
git push --follow-tags origin main
```

## Release Process

### 1. Verify State

```bash
# Ensure clean state
git status

# Run all checks
make qa
```

### 2. Preview Release

```bash
make release/dry-run
```

This shows:

- Current version
- New version
- Commits that will be included
- CHANGELOG entries that will be added

### 3. Execute Release

Choose the appropriate release type:

```bash
# For bug fixes
make release/patch

# For new features
make release/minor

# For breaking changes
make release/major
```

This will:

1. Update `.semver` with new version
2. Update `Makefile` VERSION
3. Update other bump files (e.g., `pyproject.toml` if configured)
4. Generate `CHANGELOG.md` with new entries
5. Create a commit: `chore(release): vX.Y.Z`
6. Create a git tag: `vX.Y.Z`

### 4. Enrich the CHANGELOG

The auto-generated CHANGELOG only contains commit subjects. Add rich descriptions:

```bash
# Edit CHANGELOG.md with descriptive content
git add CHANGELOG.md
git commit --amend --no-edit
# Recreate the tag on the amended commit
git tag -d vX.Y.Z
git tag -a vX.Y.Z -m "chore(release): vX.Y.Z"
```

### 5. Push Release

```bash
git push --follow-tags origin main
```

## First Release

For the initial release of a project:

```bash
make release/first
```

**IMPORTANT:**

- The initial commit MUST have all versions at `0.0.0` (`.semver`, `Makefile`, etc.)
- The `CHANGELOG.md` MUST be empty (no header — the tool generates it)
- `make release/first` uses `--release-as minor` internally to bump `0.0.0 → 0.1.0`
- Do NOT use `commit-and-tag-version --first-release` — it skips the version bump entirely

After the first release, enrich the CHANGELOG and amend (see step 4 above).

## Hotfixes

For urgent fixes to production:

1. Ensure you're on `main` with latest
2. Make the fix with conventional commit: `fix(scope): description`
3. Release patch: `make release/patch`
4. Push: `git push --follow-tags origin main`

## Troubleshooting

### "No commits since last release"

All commits since the last tag are already included. Make new commits before releasing.

### "Working directory not clean"

Commit or stash your changes:

```bash
git stash
make release/patch
git stash pop
```

### Wrong version released

If you released the wrong version type:

```bash
# Delete the tag locally and remotely
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z

# Reset to before the release commit
git reset --hard HEAD~1

# Try again with correct type
make release/minor  # or patch/major
```

### CHANGELOG header duplicated

The `CHANGELOG.md` file must start empty. The header is defined in `config.header` inside
`.versionrc.js`. If you see duplicated headers, remove the content from `CHANGELOG.md` (keep it
empty), amend the commit, and re-run the release.

### pyproject.toml not bumped

If using Python projects, ensure the `writeVersion` regex in `.versionrc.js` has the `/m`
(multiline) flag. Without it, the regex won't match `version = "..."` because it's not at the
start of the file.

## Configuration Files

| File                    | Purpose                            |
|-------------------------|------------------------------------|
| `.semver`               | Single source of truth for version |
| `.versionrc.js`         | Release tool configuration         |
| `.changelog-templates/` | CHANGELOG format templates         |
| `CHANGELOG.md`          | Generated changelog                |
| `Makefile`              | Release targets + version string   |

## Adding New Bump Files

When adding a new file to `.versionrc.js` `bumpFiles` (e.g., `pyproject.toml`):

1. Add the entry with `readVersion`/`writeVersion` updater to `.versionrc.js`
2. Add the filename to `RELEASE_FILES` in the `Makefile`
3. Ensure regex uses `/m` flag if the version string is not at the start of the file

## Related

- [commits.md](./commits.md) - Commit message format
- [versioning.md](./versioning.md) - Version strategy
- [changelog.md](./changelog.md) - CHANGELOG generation
