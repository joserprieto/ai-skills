#### 5.2 Issue Management Library

Scripts in `.github/scripts/issues/` provide reusable primitives for GitHub issue management.

##### `.github/scripts/issues/lib/common.sh`

```bash
#!/usr/bin/env bash
# Shared functions and constants for issue management scripts.
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

set -euo pipefail

# ── Color Configuration ───────────────────────────────────────────────
if [[ -t 1 ]]; then
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_RESET='\033[0m'
else
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_RESET=''
fi

# ── Logging ───────────────────────────────────────────────────────────
log_info()    { echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2; }
log_error()   { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2; }
log_success() { echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*" >&2; }
log_warn()    { echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2; }

# ── Label Constants ───────────────────────────────────────────────────
# shellcheck disable=SC2034
readonly LABEL_CI_FAILURE="ci-failure"
# shellcheck disable=SC2034
readonly LABEL_AUTOMATED="automated"

# Repository — CHANGE THIS to match your GitHub owner/repo
# shellcheck disable=SC2034
readonly REPO="OWNER/PROJECT"

# ── Validation ────────────────────────────────────────────────────────
validate_gh_auth() {
    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI is not authenticated."
        log_error "Set GH_TOKEN or GITHUB_TOKEN, or run 'gh auth login'."
        return 1
    fi
    log_info "GitHub CLI authentication verified."
}

require_gh_cli() {
    if ! command -v gh &>/dev/null; then
        log_error "'gh' CLI is not installed. See: https://cli.github.com/"
        return 1
    fi
}

check_prerequisites() {
    require_gh_cli
    validate_gh_auth
}
```

**IMPORTANT:** Replace `OWNER/PROJECT` in the `REPO` constant with the actual GitHub owner/repo.

##### `.github/scripts/issues/create.sh`

```bash
#!/usr/bin/env bash
# Creates a GitHub issue. Prints issue number to stdout.
# Usage: create.sh --title "..." --body "..." --labels "label1,label2"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

TITLE="" BODY="" LABELS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --title)  TITLE="$2";  shift 2 ;;
        --body)   BODY="$2";   shift 2 ;;
        --labels) LABELS="$2"; shift 2 ;;
        *) log_error "Unknown argument: $1"; exit 1 ;;
    esac
done

[[ -z "${TITLE}" ]] && { log_error "Missing --title"; exit 1; }
[[ -z "${BODY}" ]]  && { log_error "Missing --body"; exit 1; }

check_prerequisites

log_info "Creating issue: ${TITLE}"

GH_ARGS=(issue create --repo "${REPO}" --title "${TITLE}" --body "${BODY}")
[[ -n "${LABELS}" ]] && GH_ARGS+=(--label "${LABELS}")

ISSUE_URL="$(gh "${GH_ARGS[@]}")"
[[ -z "${ISSUE_URL}" ]] && { log_error "Failed to create issue."; exit 1; }

ISSUE_NUMBER="$(basename "${ISSUE_URL}")"
log_success "Issue #${ISSUE_NUMBER} created: ${ISSUE_URL}"
echo "${ISSUE_NUMBER}"
```

##### `.github/scripts/issues/search.sh`

```bash
#!/usr/bin/env bash
# Searches open issues by labels. Prints matching issue numbers (one per line).
# Usage: search.sh --labels "label1,label2"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

LABELS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --labels) LABELS="$2"; shift 2 ;;
        *) log_error "Unknown argument: $1"; exit 1 ;;
    esac
done

[[ -z "${LABELS}" ]] && { log_error "Missing --labels"; exit 1; }

check_prerequisites

log_info "Searching for open issues with labels: ${LABELS}"

RESULTS="$(gh issue list \
    --repo "${REPO}" \
    --label "${LABELS}" \
    --state open \
    --json number \
    --jq '.[].number' \
    2>/dev/null || true)"

if [[ -z "${RESULTS}" ]]; then
    log_info "No open issues found matching labels: ${LABELS}"
    exit 0
fi

COUNT="$(echo "${RESULTS}" | wc -l | tr -d ' ')"
log_info "Found ${COUNT} open issue(s) matching labels: ${LABELS}"
echo "${RESULTS}"
```

##### `.github/scripts/issues/close.sh`

```bash
#!/usr/bin/env bash
# Closes a GitHub issue with an optional comment.
# Usage: close.sh --issue <number> [--comment "..."]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ISSUE_NUMBER="" COMMENT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --issue)   ISSUE_NUMBER="$2"; shift 2 ;;
        --comment) COMMENT="$2";      shift 2 ;;
        *) log_error "Unknown argument: $1"; exit 1 ;;
    esac
done

[[ -z "${ISSUE_NUMBER}" ]] && { log_error "Missing --issue"; exit 1; }
[[ ! "${ISSUE_NUMBER}" =~ ^[0-9]+$ ]] && { log_error "Issue number must be integer"; exit 1; }

check_prerequisites

if [[ -n "${COMMENT}" ]]; then
    log_info "Adding comment to issue #${ISSUE_NUMBER}..."
    gh issue comment "${ISSUE_NUMBER}" --repo "${REPO}" --body "${COMMENT}"
    log_success "Comment added to issue #${ISSUE_NUMBER}."
fi

log_info "Closing issue #${ISSUE_NUMBER}..."
gh issue close "${ISSUE_NUMBER}" --repo "${REPO}" --reason "completed"
log_success "Issue #${ISSUE_NUMBER} closed."
```
