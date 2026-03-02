#### 5.3 CI Auto-Issue Scripts

These scripts wrap the issue library for CI-specific use cases. They are called from the CI workflow
(`ci-summary` job) on main-branch runs only.

##### `.github/scripts/ci/on-failure.sh`

```bash
#!/usr/bin/env bash
# Creates a GitHub issue when a CI job fails. Deduplicates (skips if open issue exists).
# Usage: on-failure.sh <job-name> <run-url>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISSUES_DIR="${SCRIPT_DIR}/../issues"

# shellcheck source=../issues/lib/common.sh
source "${ISSUES_DIR}/lib/common.sh"

[[ $# -lt 2 ]] && { log_error "Usage: on-failure.sh <job-name> <run-url>"; exit 1; }

JOB_NAME="$1"
RUN_URL="$2"

COMMIT_SHA="${GITHUB_SHA:-unknown}"
ACTOR="${GITHUB_ACTOR:-unknown}"
BRANCH="${GITHUB_REF_NAME:-main}"

log_info "CI failure detected for job: ${JOB_NAME}"

TITLE="CI Failure: ${JOB_NAME} failed on ${BRANCH}"

BODY="## CI Job Failure

The **${JOB_NAME}** job failed on the **${BRANCH}** branch.

### Details

| Field | Value |
|-------|-------|
| **Job** | \`${JOB_NAME}\` |
| **Branch** | \`${BRANCH}\` |
| **Commit** | \`${COMMIT_SHA:0:8}\` |
| **Triggered by** | @${ACTOR} |
| **Run URL** | [View Logs](${RUN_URL}) |
| **Timestamp** | $(date -u '+%Y-%m-%d %H:%M:%S UTC') |

### Next Steps

1. Check the [workflow run logs](${RUN_URL}) for details
2. Fix the failing job
3. This issue will be **automatically closed** when the job passes on \`${BRANCH}\`

---
*This issue was automatically created by the CI pipeline.*"

LABELS="${LABEL_CI_FAILURE},${LABEL_AUTOMATED},job:${JOB_NAME}"

# ── Deduplication: skip if an open issue already exists ───────────────
EXISTING="$("${ISSUES_DIR}/search.sh" --labels "${LABELS}" 2>/dev/null || true)"

if [[ -n "${EXISTING}" ]]; then
    FIRST_ISSUE="$(echo "${EXISTING}" | head -n 1)"
    log_warn "Open CI failure issue already exists for '${JOB_NAME}': #${FIRST_ISSUE}"
    log_info "Skipping issue creation to avoid duplicates."
    exit 0
fi

ISSUE_NUMBER="$("${ISSUES_DIR}/create.sh" \
    --title "${TITLE}" \
    --body "${BODY}" \
    --labels "${LABELS}")"

log_success "Created CI failure issue #${ISSUE_NUMBER} for job '${JOB_NAME}'."
```

##### `.github/scripts/ci/on-success.sh`

```bash
#!/usr/bin/env bash
# Closes open CI failure issues when the job passes.
# Usage: on-success.sh <job-name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISSUES_DIR="${SCRIPT_DIR}/../issues"

# shellcheck source=../issues/lib/common.sh
source "${ISSUES_DIR}/lib/common.sh"

[[ $# -lt 1 ]] && { log_error "Usage: on-success.sh <job-name>"; exit 1; }

JOB_NAME="$1"

COMMIT_SHA="${GITHUB_SHA:-unknown}"
ACTOR="${GITHUB_ACTOR:-unknown}"
SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
REPOSITORY="${GITHUB_REPOSITORY:-OWNER/PROJECT}"
RUN_ID="${GITHUB_RUN_ID:-}"

log_info "CI success for job: ${JOB_NAME} - checking for open failure issues..."

SEARCH_LABELS="${LABEL_CI_FAILURE},${LABEL_AUTOMATED},job:${JOB_NAME}"
ISSUE_NUMBERS="$("${ISSUES_DIR}/search.sh" --labels "${SEARCH_LABELS}" 2>/dev/null || true)"

if [[ -z "${ISSUE_NUMBERS}" ]]; then
    log_info "No open CI failure issues found for job '${JOB_NAME}'. Nothing to close."
    exit 0
fi

RUN_URL_PART=""
if [[ -n "${RUN_ID}" ]]; then
    RUN_URL_PART="
| **Passing run** | [View Logs](${SERVER_URL}/${REPOSITORY}/actions/runs/${RUN_ID}) |"
fi

COMMENT="## Resolved

The **${JOB_NAME}** job is now passing on the main branch.

| Field | Value |
|-------|-------|
| **Job** | \`${JOB_NAME}\` |
| **Fixed in commit** | \`${COMMIT_SHA:0:8}\` |
| **Fixed by** | @${ACTOR} |${RUN_URL_PART}
| **Resolved at** | $(date -u '+%Y-%m-%d %H:%M:%S UTC') |

---
*This issue was automatically closed by the CI pipeline.*"

CLOSED_COUNT=0

while IFS= read -r ISSUE_NUMBER; do
    [[ -z "${ISSUE_NUMBER}" ]] && continue

    log_info "Closing issue #${ISSUE_NUMBER}..."

    "${ISSUES_DIR}/close.sh" \
        --issue "${ISSUE_NUMBER}" \
        --comment "${COMMENT}" || {
            log_error "Failed to close issue #${ISSUE_NUMBER}. Continuing..."
            continue
        }

    CLOSED_COUNT=$((CLOSED_COUNT + 1))
done <<< "${ISSUE_NUMBERS}"

if [[ ${CLOSED_COUNT} -gt 0 ]]; then
    log_success "Closed ${CLOSED_COUNT} CI failure issue(s) for job '${JOB_NAME}'."
else
    log_warn "No issues were closed (all close attempts may have failed)."
fi
```
