#!/usr/bin/env bash
# ====================================================================================
# on-success.sh - Closes CI failure issues when the job passes
# ====================================================================================
#
# Usage:
#   on-success.sh <job-name>
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

if [[ $# -lt 1 ]]; then
    log_error "Usage: on-success.sh <job-name>"
    exit 1
fi

JOB_NAME="$1"

COMMIT_SHA="${GITHUB_SHA:-unknown}"
ACTOR="${GITHUB_ACTOR:-unknown}"
SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
REPOSITORY="${GITHUB_REPOSITORY:-joserprieto/ai-skills}"
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
