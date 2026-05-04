# Release Workflow

This repo has **two independent release flows** because of its dual-versioning model
([versioning.md](./versioning.md)). Each one is triggered differently and serves a different
audience.

## Flow 1 — Per-skill release (the common case)

Every change to a skill gets a version bump in its own `SKILL.md` frontmatter. There's no tooling
ceremony — just a manual edit and a commit with the new version in the subject line.

### Process

1. Edit the skill: change `SKILL.md`, references, examples, whatever.
2. Decide the bump per
   [versioning.md §"Bump rules per skill"](./versioning.md#bump-rules-per-skill).
3. Update the frontmatter:

   ```yaml
   metadata:
     version: '0.5.1' # was 0.5.0
   ```

4. Run `make skills/index` to refresh the README table (otherwise pre-commit will block you).
5. Stage + commit with the version in the subject:

   ```
   fix(drawio-uml-shapes): v0.5.1 — warn about mxGeometry requirement on edges
   ```

6. Push. CI verifies the README is in sync.

That's it. No tag, no `make release/*`, no CHANGELOG ceremony — the commit history **is** the audit
trail for that skill, and `git log -- skills/<name>/` gives the full timeline.

### When to bump

See [versioning.md §"Bump rules per skill"](./versioning.md#bump-rules-per-skill). Quick rule: typo
or clarification → patch; new trigger or section → minor; breaking change to triggers or behaviour →
major.

## Flow 2 — Repo release (rare)

Reserved for changes at the meta-project level: tooling, conventions, infrastructure shared across
all skills. Bumps `.semver`, regenerates `CHANGELOG.md`, creates a `vX.Y.Z` tag.

### Prerequisites

- Clean working directory (`git status` shows no changes).
- All quality checks passing (`make qa`).
- On `main` branch.

### Process

```bash
# Show current repo version
cat .semver

# Preview the next bump (no changes written)
make release/dry-run

# Choose the right bump:
make release/patch     # Bug fix in tooling/infra (0.1.0 → 0.1.1)
make release/minor     # New convention or automation (0.1.0 → 0.2.0)
make release/major     # Breaking change in repo conventions (0.1.0 → 1.0.0)

# Push with tags
git push --follow-tags origin main
```

The `make release/*` targets use
[commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) to:

1. Update `.semver` with the new version.
2. Update other files listed in `bumpFiles` of `.versionrc.js`.
3. Generate `CHANGELOG.md` from conventional-commit history.
4. Create a commit `chore(release): vX.Y.Z`.
5. Create a git tag `vX.Y.Z`.

### When to use Flow 2

- Major restructure of `docs/conventions/`.
- New cross-skill automation (the way `skills/index` was added).
- Breaking change in CI workflow that affects how skills are validated.
- A "milestone" that's meaningful to consumers tracking the meta-repo.

For most week-to-week work, Flow 1 (per-skill) is what you'll use. Flow 2 is for moments worth
remembering.

### Enriching the CHANGELOG (after a Flow 2 release)

The auto-generated CHANGELOG only contains commit subjects. Add rich descriptions before pushing:

```bash
# Edit CHANGELOG.md with descriptive content
git add CHANGELOG.md
git commit --amend --no-edit

# Recreate the tag on the amended commit
git tag -d vX.Y.Z
git tag -a vX.Y.Z -m "chore(release): vX.Y.Z"

# Push
git push --follow-tags origin main
```

## Troubleshooting

### "No commits since last release"

All commits since the last tag are already included. Make new commits before running
`make release/*`.

### "Working directory not clean"

Commit or stash your changes first:

```bash
git stash
make release/patch
git stash pop
```

### Wrong release type used

If you ran `make release/minor` when you meant `release/patch`:

```bash
# Delete the tag locally and remotely
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z

# Reset to before the release commit
git reset --hard HEAD~1

# Try again with the right type
make release/patch
```

### CHANGELOG header duplicated

`CHANGELOG.md` must start empty. The header is defined in `config.header` inside `.versionrc.js`. If
duplicated, remove the content from `CHANGELOG.md` (leave it empty), amend the commit, re-run the
release.

## Configuration files

| File                    | Purpose                                                                                           |
| ----------------------- | ------------------------------------------------------------------------------------------------- |
| `.semver`               | Repo version (single source of truth for Flow 2)                                                  |
| `.versionrc.js`         | Release tool configuration (Flow 2)                                                               |
| `.changelog-templates/` | CHANGELOG format templates (Flow 2)                                                               |
| `CHANGELOG.md`          | Generated changelog (Flow 2)                                                                      |
| `skills/*/SKILL.md`     | Per-skill version in frontmatter `metadata.version` (Flow 1)                                      |
| `README.md`             | Auto-generated table reflecting current per-skill versions ([skills-index.md](./skills-index.md)) |

## Related

- [versioning.md](./versioning.md) — Why two streams exist.
- [commits.md](./commits.md) — Commit message format (per-skill scope carries the bumped version).
- [changelog.md](./changelog.md) — CHANGELOG generation (Flow 2 only).
- [skills-index.md](./skills-index.md) — Auto-generated skill index.
