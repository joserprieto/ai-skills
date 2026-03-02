#### 5.7 Optional Workflows

These workflows are not required for the base setup but are recommended for mature projects.

##### GitHub Release from Tags — `.github/workflows/release.yml`

Automatically creates a GitHub Release with auto-generated notes when you push a version tag (e.g.,
after `make release` + `git push --tags`). This gives your project a proper Releases page with
downloadable source archives.

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    name: Create GitHub Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Extract version from tag
        id: version
        run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      - name: Extract changelog for this version
        id: changelog
        run: |
          # Extract the section for the current version from CHANGELOG.md
          VERSION="${{ steps.version.outputs.version }}"
          CHANGELOG=$(awk "/^## \[?${VERSION}\]?/{found=1; next} /^## /{if(found) exit} found{print}" CHANGELOG.md)

          if [[ -z "${CHANGELOG}" ]]; then
            CHANGELOG="Release ${GITHUB_REF_NAME}"
          fi

          # Write to file to avoid quoting issues
          echo "${CHANGELOG}" > /tmp/release-notes.md

      - name: Create GitHub Release
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release create "${{ github.ref_name }}" \
            --title "${{ github.ref_name }}" \
            --notes-file /tmp/release-notes.md \
            --verify-tag
```

**How it works:**

1. `make release` bumps version, commits, and creates a `vX.Y.Z` tag locally
2. `git push --tags` pushes the tag to GitHub
3. The workflow triggers on `v*` tags, extracts the matching section from `CHANGELOG.md`, and
   creates a GitHub Release
4. `--verify-tag` ensures the tag exists (prevents accidental release from re-runs)
5. `fetch-depth: 0` is needed to access the full CHANGELOG.md history

##### Stale Issues and PRs — `.github/workflows/stale.yml`

Automatically labels and closes issues/PRs that have had no activity for a configurable period. This
prevents the issue tracker from filling up with abandoned items.

```yaml
name: Stale Issues and PRs

on:
  schedule:
    - cron: '30 6 * * 1' # Every Monday at 06:30 UTC
  workflow_dispatch:

permissions:
  issues: write
  pull-requests: write

jobs:
  stale:
    name: Close Stale Issues and PRs
    runs-on: ubuntu-latest
    steps:
      - name: Mark and close stale items
        uses: actions/stale@v9
        with:
          # Issues
          days-before-stale: 60
          days-before-close: 14
          stale-issue-label: 'stale'
          stale-issue-message: >
            This issue has been automatically marked as stale because it has had no activity for 60
            days. It will be closed in 14 days if no further activity occurs. If this issue is still
            relevant, please comment to keep it open.
          close-issue-message: >
            This issue has been automatically closed due to inactivity. Feel free to reopen if the
            issue persists.
          exempt-issue-labels: 'pinned,security,ci-failure'
          # Pull Requests
          days-before-pr-stale: 30
          days-before-pr-close: 7
          stale-pr-label: 'stale'
          stale-pr-message: >
            This pull request has been automatically marked as stale because it has had no activity
            for 30 days. It will be closed in 7 days if no further activity occurs.
          close-pr-message: >
            This pull request has been automatically closed due to inactivity. Feel free to reopen
            if the changes are still needed.
          exempt-pr-labels: 'pinned,dependencies'
```

**Key configuration choices:**

- **`exempt-issue-labels: 'pinned,security,ci-failure'`** — Never auto-close security issues or
  CI-created failure issues. These require human resolution.
- **`exempt-pr-labels: 'pinned,dependencies'`** — Don't auto-close dependabot PRs; they have their
  own lifecycle.
- **Schedule: `30 6 * * 1`** — Runs weekly on Monday mornings (UTC). Frequent enough to keep things
  tidy, infrequent enough to avoid noise.
- **`workflow_dispatch`** — Allows manual triggering for initial cleanup after enabling.
