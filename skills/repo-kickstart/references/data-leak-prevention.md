## Data Leak Prevention

OSS repos MUST NOT contain personal data beyond the designated contact email.

### Email Obfuscation

In `CODE_OF_CONDUCT.md` and `SECURITY.md`, ALWAYS obfuscate emails to prevent automated scraping:

```markdown
<!-- GOOD — anti-scraping format -->

**hi [at] example [dot] com**

<!-- BAD — trivially scrapeable -->

hi@example.com <a href="mailto:hi@example.com">
```

The contact email SHOULD be the same as the git author email. Ask the user during setup (Step 1).

### Contact email — the only-one rule

The ONLY email allowed in committed files is the project's **public contact email** — the one shown
on the maintainer's public profile (`gh api users/<login> --jq .email`). Any OTHER email (a personal
address like `jose@example.com`, a teammate's, etc.) is treated as a leak and blocks the commit.

### Allowing PII on purpose: `pii-allow` markers (PRIVATE repos only)

A file in a PRIVATE repo may need PII on purpose (e.g. a real email-signature template). Authorize
it explicitly, per file, with a marker in that same file:

```text
<!-- pii-allow: jose@example.com, 600 000 000 | reason: real signature, only used in mail from jose@example.com -->
```

- Items before the `|` are exempt from leak detection IN THAT FILE ONLY.
- The `reason:` after `|` is MANDATORY — it documents why the exception exists.
- Anything not covered by a marker (any non-contact email, any matched secret) still blocks.

**PUBLIC repos: never.** A `pii-allow` marker authorizes against _accidental detection_, not against
_visibility_. In a public repo, real PII must not be present at all — the marker is not a licence to
expose it. The repo's visibility is the question you answer BEFORE any allowlist.

### Pre-commit Hook: Personal Data Detection

Create `.githooks/pre-commit` to scan staged files for accidental personal data leaks:

```bash
#!/bin/bash
# Pre-commit hook: block personal-data / secret leaks in staged files.
set -euo pipefail

LEAK_PATTERNS=(
    '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'   # any email
    'AKIA[0-9A-Z]{16}'                                  # AWS access key
    'sk-[a-zA-Z0-9]{20,}'                               # OpenAI/Stripe key
    'ghp_[a-zA-Z0-9]{36}'                               # GitHub PAT
    'glpat-[a-zA-Z0-9_-]{20}'                           # GitLab PAT
    'xox[bprs]-[a-zA-Z0-9-]+'                           # Slack token
)

# Globally benign: git SSH remotes (git@host), RFC 2606 example domains
# (example.com/.org/.net), and YOUR public contact email (replace below).
# EVERYTHING else is a leak unless covered by a per-file pii-allow marker.
LEAK_ALLOWLIST='^git@[a-zA-Z0-9.-]+$|@example\.(com|org|net)$|^hi@example\.com$'

fail=0
staged=$(git diff --cached --name-only --diff-filter=ACM)
[ -z "$staged" ] && exit 0

for f in $staged; do
    file "$f" 2>/dev/null | grep -q text || continue
    content=$(git show ":$f" 2>/dev/null || true)
    [ -z "$content" ] && continue
    # Per-file allowance: "pii-allow: a@b, 600 000 000 | reason: ..."
    allow=$(echo "$content" | grep -oE 'pii-allow:[^|]*' \
        | sed -E 's/^pii-allow:[[:space:]]*//' | tr ',' '\n' \
        | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^$' || true)
    for pat in "${LEAK_PATTERNS[@]}"; do
        hits=$(echo "$content" | grep -oE "$pat" | grep -vE "$LEAK_ALLOWLIST" || true)
        [ -n "$allow" ] && [ -n "$hits" ] && hits=$(echo "$hits" | grep -vxF "$allow" || true)
        if [ -n "$hits" ]; then
            printf '\033[31mLEAK\033[0m %s — %s\n' "$f" "$(echo "$hits" | tr '\n' ' ')"
            fail=1
        fi
    done
done

[ "$fail" -ne 0 ] && { printf '\nCommit blocked. Remove the data, or add a pii-allow marker (private repos only).\n'; exit 1; }
exit 0
```

Set `LEAK_ALLOWLIST` to your public contact email. Everything else — any other email, plus
AWS/OpenAI/GitHub/GitLab/Slack secret formats — blocks the commit unless a per-file `pii-allow`
marker exempts it (private repos only; see above).

**Hook installation** (add to Makefile `install` target or document in CONTRIBUTING.md):

```bash
git config core.hooksPath .githooks
```

### History Purge Checklist

If personal data has already been committed, removing it from tracked files is NOT enough — it
remains in git history. Use `git filter-repo` to rewrite history:

```bash
# 1. Backup
git clone --mirror origin-url backup.git

# 2. Purge paths containing personal data
git filter-repo --invert-paths --path docs/plans/ --path secrets/

# 3. Force push (DESTRUCTIVE — coordinate with collaborators)
git remote add origin <url>
git push --force --all
git push --force --tags

# 4. All collaborators must re-clone (rebase won't work after filter-repo)
```

**IMPORTANT:** `git filter-repo` removes the `origin` remote as a safety measure. You must re-add it
manually after the rewrite.

### Empty Directory Tracking: .gitignore > .gitkeep

**ALWAYS use `.gitignore` files instead of `.gitkeep` to track empty directories.** The `.gitignore`
pattern is strictly superior:

```gitignore
# .gitignore inside the empty directory (e.g., .keys/age/.gitignore)
*
!.gitignore
```

**Why this is better than `.gitkeep`:**

| Aspect                      | `.gitkeep`                            | `.gitignore` pattern                      |
| --------------------------- | ------------------------------------- | ----------------------------------------- |
| Prevents accidental commits | No — any file can be added            | Yes — `*` blocks all files                |
| Self-documenting            | No — empty file with no semantics     | Yes — explicitly declares intent          |
| Orphan risk                 | High — `.gitkeep` files get forgotten | None — `.gitignore` is self-contained     |
| Subdirectory support        | No — just tracks the directory        | Yes — use `!subdir` to whitelist children |

**For sensitive directories** (keys, secrets), the `.gitignore` pattern actively protects against
accidental commits of private material. A `.gitkeep` provides zero protection.

**Example for a keys directory:**

```
.keys/
├── .gitignore          # * / !.gitignore / !age
└── age/
    └── .gitignore      # * / !.gitignore
```

### .gitignore Patterns for Sensitive Directories

Always include these in `.gitignore` for directories that may contain personal notes or local plans:

```gitignore
# Local-only documents (may contain personal data)
docs/plans/
*.local
*.local.*
.env.local
```

## Common Mistakes
