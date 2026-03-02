#### 5.1 Labels (prerequisite for CI + dependabot)

Labels MUST exist in the GitHub repository BEFORE the CI workflow can tag issues or dependabot can
tag PRs. Define them in `.github/config/labels.json` and sync with a dedicated workflow.

**IMPORTANT:** If a label referenced by dependabot or CI scripts does not exist, it is silently
ignored — PRs/issues are created without labels, and search-by-label queries return no results
(breaking auto-close). Always run the labels sync workflow first.

##### `.github/config/labels.json`

```json
[
  { "name": "ci-failure", "color": "d73a4a", "description": "Automated CI failure issue" },
  { "name": "automated", "color": "0075ca", "description": "Created automatically by CI" },
  {
    "name": "job:lint-markdown",
    "color": "e4e669",
    "description": "Related to markdown lint CI job"
  },
  { "name": "job:lint-shell", "color": "e4e669", "description": "Related to shell lint CI job" },
  {
    "name": "job:format-check",
    "color": "e4e669",
    "description": "Related to format check CI job"
  },
  { "name": "bug", "color": "d73a4a", "description": "Something isn't working" },
  { "name": "enhancement", "color": "a2eeef", "description": "New feature or request" },
  {
    "name": "documentation",
    "color": "0075ca",
    "description": "Improvements or additions to documentation"
  },
  { "name": "good first issue", "color": "7057ff", "description": "Good for newcomers" },
  { "name": "question", "color": "d876e3", "description": "Further information is requested" },
  { "name": "dependencies", "color": "0366d6", "description": "Dependency updates" }
]
```

Adapt the `job:*` labels to match your CI job names. The `dependencies` label is required for
dependabot PRs (see [dependabot.md](../ci/dependabot.md)).

##### `.github/workflows/labels.yml`

```yaml
name: Sync Labels

on:
  push:
    branches: [main]
    paths:
      - '.github/config/labels.json'
  workflow_dispatch:

permissions:
  issues: write

jobs:
  sync:
    name: Sync Labels
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Sync labels
        uses: EndBug/label-sync@v2
        with:
          config-file: .github/config/labels.json
          delete-other-labels: false
```

`delete-other-labels: false` preserves any manually created labels. Set to `true` for strict
label-as-code enforcement.

**First-time setup:** After the initial commit, either push to main (triggers the workflow) or run
it manually via `gh workflow run labels.yml`. Labels must be synced BEFORE the first CI failure or
dependabot PR.
