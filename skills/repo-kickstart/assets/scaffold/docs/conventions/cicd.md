# CI/CD Pipeline

Continuous Integration and Continuous Delivery conventions for the project.

## Principles

- **Every push is verified**: Linting, formatting, and tests run on every push and PR
- **Parallel execution**: Independent jobs run in parallel for fast feedback
- **Fail fast**: Quality gate (`make qa`) blocks releases if anything fails
- **Self-healing**: Pipeline failures automatically create trackable issues; fixes auto-close them
- **Supply chain security**: Pin all third-party dependencies (actions, tools) to immutable
  references (commit SHAs, checksums)

## Pipeline Structure

```
Push to main / PR
  │
  ├── lint-markdown    (parallel)
  ├── lint-shell       (parallel)
  ├── format-check     (parallel)
  ├── test             (parallel, if configured)
  │
  └── ci-summary       (depends on all above)
      ├── On failure → create trackable issue
      └── On success → close existing issue
```

## Quality Gate

The CI pipeline enforces the same checks as `make qa` locally:

```bash
make qa    # lint + format check + test (if configured)
```

If any job fails, the pipeline blocks merging (via branch protection rules) and the summary job
handles issue tracking.

## Security Considerations

- **Pin dependencies to immutable refs**: Use commit SHAs for actions, checksums for binaries
- **Minimal permissions**: Request only the permissions each job needs
- **No secret interpolation in shell**: Pass secrets via environment variables, not inline
- **Concurrency control**: Only one CI run per branch; new pushes cancel in-progress runs

## Adding a New CI Job

When adding a new lint/test job to the pipeline:

1. Add the job definition (parallel with existing jobs)
2. Add it to the summary job's dependency list
3. Add failure/success handling in the summary job
4. Add corresponding label for issue tracking (if using auto-issue)

<!-- ====================================================================
     GITHUB ACTIONS SPECIFICS
     Include this section ONLY if the project uses GitHub as its platform.
     Delete this section if using GitLab CI, Jenkins, or another CI system.
     ==================================================================== -->

## GitHub Actions Implementation

This section applies only to projects hosted on GitHub.

### Workflows

| Workflow         | Trigger                  | Purpose                          |
| ---------------- | ------------------------ | -------------------------------- |
| `ci.yml`         | Push to main, PRs        | Main CI pipeline                 |
| `labels.yml`     | Changes to labels config | Sync GitHub labels               |
| `release.yml`    | Version tag pushed       | Create GitHub Release (optional) |
| `stale.yml`      | Scheduled                | Close stale issues/PRs           |
| `dependabot.yml` | Scheduled (weekly)       | Automated dependency updates     |

### Self-Healing Issue Management

When a CI job **fails**, an issue is automatically created:

- Title: `CI Failure: <job-name>`
- Label: `job:<job-name>` (e.g., `job:lint-markdown`)
- Body: Link to the failed run

When that job **passes** again, the issue is automatically closed with a comment.

Only **one issue per job** exists at a time — duplicates are prevented by label-based search.

**Prerequisite:** Labels MUST exist before CI can tag issues. Run the labels sync workflow first:

```bash
gh workflow run labels.yml
```

### Issue Management Scripts

```
.github/scripts/
├── ci/
│   ├── on-failure.sh    # Create/update issue on CI failure
│   └── on-success.sh    # Close issue on CI success
└── issues/
    ├── create.sh        # Create a labeled issue
    ├── search.sh        # Find existing issues by label
    ├── close.sh         # Close an issue with comment
    └── lib/common.sh    # Shared logging + constants
```

### Action versioning (floating tags vs SHA pins)

Third-party GitHub Actions can be referenced two ways. Choose based on the project's risk profile:

```yaml
# Floating tag — preferred default. Dependabot keeps it current.
- uses: actions/checkout@v4

# SHA pin — recommended for security-critical pipelines (handling secrets,
# touching production, supply-chain hardening). Trades dependabot ergonomics
# for immutability against tag mutation attacks.
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

The default scaffold uses floating tags + dependabot — that's the configuration most OSS projects
adopt. Move to SHA pinning when (a) the workflow runs against production, (b) the repo handles
sensitive secrets, or (c) you've adopted a supply-chain hardening posture explicitly.

### Adding a GitHub Actions CI Job (Checklist)

1. Add the job to `jobs:` in `ci.yml` (parallel with others)
2. Add it to `ci-summary.needs: [...]`
3. Add env var + output in `Determine overall result` step
4. Add the env var to the `if` condition in `Determine overall result`
5. Add a row in `Print summary`
6. Add `Handle <job> failure` and `Handle <job> success` steps
7. Add a `job:<job-name>` label to `.github/config/labels.json`
8. Run the labels sync workflow

### Optional: GitHub Release from Tags (`release.yml`)

Automatically creates a GitHub Release when a version tag (`v*`) is pushed. The workflow extracts
the matching section from `CHANGELOG.md` and uses it as release notes.

**Flow:**

```
make release/patch → git push --tags → release.yml triggers → GitHub Release created
```

**Configuration:** No configuration needed beyond the workflow file. Uses `gh release create` with
`--verify-tag` to prevent accidental releases.

**When to enable:** Always — it provides a Releases page with downloadable source archives and
formatted changelogs at zero cost. There is no downside.

### Optional: Stale Issues and PRs (`stale.yml`)

Automatically labels and closes issues/PRs that have had no activity for a configurable period. Runs
weekly (Monday mornings UTC) via schedule.

**Timing defaults:**

| Item          | Mark stale after | Close after               |
| ------------- | ---------------- | ------------------------- |
| Issues        | 60 days inactive | 14 days after stale label |
| Pull Requests | 30 days inactive | 7 days after stale label  |

**Exempt labels:** Items with `pinned`, `security`, or `ci-failure` labels are never auto-closed.
Dependabot PRs are exempt via the `dependencies` label.

**When to enable:** Public repos with external contributors, or any repo where issues/PRs accumulate
without resolution. Skip for private single-contributor repos.

**Manual trigger:** Run `gh workflow run stale.yml` for initial cleanup after enabling.

<!-- END GITHUB ACTIONS SPECIFICS -->

## Related

- [build-tools.md](./build-tools.md) - Make targets including `qa`
- [releases.md](./releases.md) - Release workflow
- [testing.md](./testing.md) - Testing approach
- [dev-workflow.md](./dev-workflow.md) - Development workflow
