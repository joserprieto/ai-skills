#### 5.4 CI Workflow

The workflow runs 3 parallel lint jobs + a `ci-summary` job that handles auto-issue management.

**Security:** All GitHub context values in `run:` blocks MUST use `env:` variables, never direct
`${{ }}` interpolation. Only safe values (ref, server_url, repository, run_id, needs.\*.result) are
used.

##### `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  issues: write

jobs:
  # ── Lint Markdown ─────────────────────────────────────────────────────
  lint-markdown:
    name: Markdown Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Run markdownlint
        uses: DavidAnson/markdownlint-cli2-action@v22
        with:
          globs: '**/*.md'
          fix: false

  # ── Lint Shell Scripts ────────────────────────────────────────────────
  lint-shell:
    name: Shell Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Run shellcheck
        uses: ludeeus/action-shellcheck@2.0.0
        with:
          scandir: '.github/scripts'
          severity: warning

  # ── Format Check ──────────────────────────────────────────────────────
  format-check:
    name: Format Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Check formatting
        run: npx prettier --check '**/*.{md,json,yml,yaml}'

  # ── CI Summary + Auto-Issue Management ────────────────────────────────
  scan-secrets:
    name: Secret Scan
    runs-on: ubuntu-latest
    env:
      GITLEAKS_VERSION: '8.30.1'
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
        with:
          # gitleaks walks whatever history is present locally, and checkout
          # defaults to fetch-depth 1. Without this, the scan sees one commit
          # and exits 0 whatever earlier commits contain.
          fetch-depth: 0

      - name: Install gitleaks (pinned, checksum-verified)
        run: |
          curl -sSLO "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
          curl -sSLO "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_checksums.txt"
          sha256sum --ignore-missing -c "gitleaks_${GITLEAKS_VERSION}_checksums.txt"
          tar -xzf "gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" gitleaks
          chmod +x gitleaks
          sudo mv gitleaks /usr/local/bin/gitleaks
          gitleaks version

      - name: Fail fast if the checkout is shallow
        run: |
          if [[ "$(git rev-parse --is-shallow-repository)" == "true" ]]; then
            echo "::error::Shallow checkout: gitleaks would scan a truncated history and pass. Set fetch-depth: 0."
            exit 1
          fi

      - name: Scan full git history for secrets
        # --redact always: Actions logs are public on a public repository.
        run: gitleaks git . --no-banner --redact

  ci-summary:
    name: CI Summary
    runs-on: ubuntu-latest
    if: always()
    needs: [lint-markdown, lint-shell, format-check, scan-secrets]
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Make scripts executable
        run:
          chmod +x .github/scripts/ci/*.sh .github/scripts/issues/*.sh
          .github/scripts/issues/lib/*.sh

      - name: Determine overall result
        id: result
        env:
          LINT_MD_RESULT: ${{ needs.lint-markdown.result }}
          LINT_SHELL_RESULT: ${{ needs.lint-shell.result }}
          FORMAT_RESULT: ${{ needs.format-check.result }}
        run: |
          echo "lint-markdown=${LINT_MD_RESULT}" >> "$GITHUB_OUTPUT"
          echo "lint-shell=${LINT_SHELL_RESULT}" >> "$GITHUB_OUTPUT"
          echo "format-check=${FORMAT_RESULT}" >> "$GITHUB_OUTPUT"

          if [[ "${LINT_MD_RESULT}" == "success" && \
                "${LINT_SHELL_RESULT}" == "success" && \
                "${FORMAT_RESULT}" == "success" ]]; then
            echo "overall=success" >> "$GITHUB_OUTPUT"
          else
            echo "overall=failure" >> "$GITHUB_OUTPUT"
          fi

      - name: Print summary
        env:
          LINT_MD_RESULT: ${{ needs.lint-markdown.result }}
          LINT_SHELL_RESULT: ${{ needs.lint-shell.result }}
          FORMAT_RESULT: ${{ needs.format-check.result }}
          OVERALL_RESULT: ${{ steps.result.outputs.overall }}
        run: |
          echo "## CI Results" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"
          echo "| Job | Status |" >> "$GITHUB_STEP_SUMMARY"
          echo "|-----|--------|" >> "$GITHUB_STEP_SUMMARY"
          echo "| Markdown Lint | \`${LINT_MD_RESULT}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Shell Lint | \`${LINT_SHELL_RESULT}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Format Check | \`${FORMAT_RESULT}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"

          if [[ "${OVERALL_RESULT}" == "success" ]]; then
            echo "**Overall: All checks passed.**" >> "$GITHUB_STEP_SUMMARY"
          else
            echo "**Overall: One or more checks failed.**" >> "$GITHUB_STEP_SUMMARY"
          fi

      # ── Failure handling (main branch only) ───────────────────────────
      - name: Handle lint-markdown failure
        if: >-
          always() && github.ref == 'refs/heads/main' && needs.lint-markdown.result == 'failure'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          RUN_URL:
            ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
        run: .github/scripts/ci/on-failure.sh "lint-markdown" "${RUN_URL}"

      - name: Handle lint-shell failure
        if: >-
          always() && github.ref == 'refs/heads/main' && needs.lint-shell.result == 'failure'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          RUN_URL:
            ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
        run: .github/scripts/ci/on-failure.sh "lint-shell" "${RUN_URL}"

      - name: Handle format-check failure
        if: >-
          always() && github.ref == 'refs/heads/main' && needs.format-check.result == 'failure'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          RUN_URL:
            ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
        run: .github/scripts/ci/on-failure.sh "format-check" "${RUN_URL}"

      # ── Success handling (main branch only) ───────────────────────────
      - name: Handle lint-markdown success
        if: >-
          always() && github.ref == 'refs/heads/main' && needs.lint-markdown.result == 'success'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: .github/scripts/ci/on-success.sh "lint-markdown"

      - name: Handle lint-shell success
        if: >-
          always() && github.ref == 'refs/heads/main' && needs.lint-shell.result == 'success'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: .github/scripts/ci/on-success.sh "lint-shell"

      - name: Handle format-check success
        if: >-
          always() && github.ref == 'refs/heads/main' && needs.format-check.result == 'success'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: .github/scripts/ci/on-success.sh "format-check"

      # ── Final gate ────────────────────────────────────────────────────
      - name: Fail if any job failed
        if: always() && steps.result.outputs.overall == 'failure'
        run: |
          echo "::error::CI failed. See individual job results above."
          exit 1
```

**Key design decisions:**

- `concurrency` cancels in-progress runs on the same branch (saves CI minutes on rapid pushes)
- `permissions` requests only `contents: read` + `issues: write` (least privilege)
- `ci-summary` runs `if: always()` so it executes even when lint jobs fail
- Each failure/success handler has its own step with an `if:` condition — this way a failure in one
  handler doesn't block others
- `RUN_URL` is built from safe GitHub context values (`server_url`, `repository`, `run_id`)

**Shell lint:** Must use `severity: warning` to skip SC1091 (note-level, flagged on dynamic `source`
paths that shellcheck can't resolve statically).
