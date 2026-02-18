#!/usr/bin/env bash
# ====================================================================================
# on-failure.sh - Creates a GitHub issue when a CI job fails
# ====================================================================================
#
# Usage:
#   on-failure.sh <job-name> <run-url>
#
# Environment:
#   GITHUB_TOKEN or GH_TOKEN must be set for authentication.
#
# ====================================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISSUES_DIR="${SCRIPT_DIR}/../issues"

# shellcheck source=../issues/lib/common.sh
source "${ISSUES_DIR}/lib/common.sh"

if [[ $# -lt 2 ]]; then
    log_error "Usage: on-failure.sh <job-name> <run-url>"
    exit 1
fi

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

EXISTING="$("${ISSUES_DIR}/search.sh" --labels "${LABELS}" 2>/dev/null || true)"

if [[ -n "${EXISTING}" ]]; then
    FIRST_ISSUE="$(echo "${EXISTING}" | head -n 1)"
    log_warn "An open CI failure issue already exists for job '${JOB_NAME}': #${FIRST_ISSUE}"
    log_info "Skipping issue creation to avoid duplicates."
    exit 0
fi

ISSUE_NUMBER="$("${ISSUES_DIR}/create.sh" \
    --title "${TITLE}" \
    --body "${BODY}" \
    --labels "${LABELS}")"

log_success "Created CI failure issue #${ISSUE_NUMBER} for job '${JOB_NAME}'."
