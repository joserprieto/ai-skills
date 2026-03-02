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

### Pre-commit Hook: Personal Data Detection

Create `.githooks/pre-commit` to scan staged files for accidental personal data leaks:

```bash
#!/bin/sh
# Pre-commit hook: detect personal data leaks in staged files
set -eu

# ── Configurable patterns ──────────────────────────────────────────────
# Add literal strings that must NEVER appear in committed files.
# One pattern per line. Lines starting with # are comments.
DENY_PATTERNS_FILE=".githooks/deny-patterns.txt"

# ── Fallback built-in patterns ─────────────────────────────────────────
# If no deny-patterns file exists, scan for common leak indicators.
BUILTIN_PATTERNS='@gmail\.com
@hotmail\.com
@yahoo\.com
@outlook\.com
/Users/[a-zA-Z]
/home/[a-zA-Z]
C:\\Users\\'

# ── Scan ───────────────────────────────────────────────────────────────
fail=0

if [ -f "$DENY_PATTERNS_FILE" ]; then
    patterns=$(grep -v '^\s*#' "$DENY_PATTERNS_FILE" | grep -v '^\s*$' || true)
else
    patterns="$BUILTIN_PATTERNS"
fi

if [ -z "$patterns" ]; then
    exit 0
fi

staged_files=$(git diff --cached --name-only --diff-filter=ACM)
[ -z "$staged_files" ] && exit 0

# NOTE: Use here-doc (not pipe) so the while loop runs in the current
# shell — variables set inside (fail=1) survive after the loop.
while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    # shellcheck disable=SC2086
    matches=$(echo "$staged_files" | xargs grep -lnE "$pat" 2>/dev/null || true)
    if [ -n "$matches" ]; then
        printf '\033[31mLEAK DETECTED\033[0m pattern: %s\n' "$pat"
        echo "$matches" | while IFS= read -r file; do
            printf '  → %s\n' "$file"
        done
        fail=1
    fi
done <<EOF
$patterns
EOF

if [ "$fail" -ne 0 ]; then
    printf '\n\033[31mCommit blocked.\033[0m Remove personal data from staged files.\n'
    printf 'If this is a false positive, add an exception to %s\n' "$DENY_PATTERNS_FILE"
    exit 1
fi
```

Create `.githooks/deny-patterns.txt` with project-specific patterns:

```text
# Personal data patterns — one regex per line
# These patterns are checked against ALL staged files on every commit.
#
# Add your personal email domains, usernames, home directory paths, etc.
# Example:
# @personal-domain\.com
# /Users/myname
# /home/myname
```

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
