### How It All Fits Together: The Release Pipeline

Before diving into CI and the Makefile, here is how the versioning and release system works
end-to-end. Understanding this flow explains **why** each tool is configured the way it is.

#### Semantic Versioning (SemVer)

Every version follows `MAJOR.MINOR.PATCH`:

| Bump      | When                                              | Example         |
| --------- | ------------------------------------------------- | --------------- |
| **PATCH** | Backwards-compatible bug fixes                    | `0.1.0 → 0.1.1` |
| **MINOR** | New backwards-compatible functionality            | `0.1.0 → 0.2.0` |
| **MAJOR** | Breaking changes that require consumers to update | `0.1.0 → 1.0.0` |

#### Conventional Commits → SemVer Mapping

The commit type determines the version bump automatically:

| Commit prefix     | SemVer bump | Changelog section         |
| ----------------- | ----------- | ------------------------- |
| `feat:`           | **minor**   | Features                  |
| `fix:`            | **patch**   | Bug Fixes                 |
| `perf:`           | **patch**   | Performance Improvements  |
| `docs:`           | —           | Documentation             |
| `refactor:`       | —           | Code Refactoring          |
| `BREAKING CHANGE` | **major**   | BREAKING CHANGES (footer) |

Commits with `hidden: true` in `.versionrc.js` (style, chore, test, ci) still trigger bumps if they
are the highest-level change, but they don't appear in the changelog.

#### Release Flow

```
make release
  │
  ├── 1. make qa  (lint all + format check — gate)
  │
  ├── 2. npx commit-and-tag-version --skip.commit --skip.tag
  │       ├── Reads current version from .semver
  │       ├── Scans git log for conventional commits since last tag
  │       ├── Determines bump type (patch/minor/major)
  │       ├── Writes new version to .semver + Makefile (via bumpFiles)
  │       └── Generates CHANGELOG.md entry (via .changelog-templates/)
  │
  ├── 3. git add CHANGELOG.md .semver Makefile
  │
  ├── 4. git commit -m "chore(release): vX.Y.Z"
  │
  └── 5. git tag -a vX.Y.Z -m "chore(release): vX.Y.Z"
```

**Why `--skip.commit --skip.tag`?** — `commit-and-tag-version` runs `git commit` and `git tag`
internally via Node's `child_process`. This has three problems:

1. It doesn't run through your local git hooks (the `.githooks/pre-commit` data leak detector is
   bypassed)
2. It doesn't respect local PATH modifications (gpg signing may fail)
3. You can't control exactly which files are staged — it may include unexpected changes

By skipping the commit and tag, the Makefile controls the entire git operation. You see exactly what
gets committed.

**Preview without side effects:**

```bash
make release/dry-run    # Shows what WOULD happen (no files changed)
```
