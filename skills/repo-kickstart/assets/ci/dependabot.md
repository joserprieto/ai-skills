#### 5.6 Dependabot

Dependabot automates dependency update PRs. Configure it in `.github/dependabot.yml`.

##### `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: 'npm'
    directory: '/'
    schedule:
      interval: 'weekly'
    labels:
      - 'dependencies'
    commit-message:
      prefix: 'chore(deps)'

  - package-ecosystem: 'github-actions'
    directory: '/'
    schedule:
      interval: 'weekly'
    labels:
      - 'dependencies'
    commit-message:
      prefix: 'ci(deps)'
```

**Critical notes about dependabot `labels`:**

| Behavior                     | Detail                                                                                                                                       |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Custom `labels` replaces ALL | Setting `labels: ['dependencies']` removes the default `dependencies` label, then re-adds your list. Use `labels: []` to disable ALL labels. |
| Labels MUST pre-exist        | If a label in the list doesn't exist in the repo, dependabot silently ignores it. The PR is created but without that label.                  |
| No auto-creation             | Unlike `gh issue create --label`, dependabot never creates missing labels.                                                                   |
| SemVer labels are separate   | Dependabot adds `major`/`minor`/`patch` labels automatically based on the version bump — these are unaffected by the `labels` option.        |

**`commit-message.prefix`** adds a conventional commit prefix to PR titles. Use `chore(deps)` for
runtime/dev dependencies and `ci(deps)` for GitHub Actions updates. This ensures dependabot PRs
follow the same commit convention as the rest of the project.

**Optional: Grouping updates** into a single PR per ecosystem:

```yaml
- package-ecosystem: 'npm'
  directory: '/'
  schedule:
    interval: 'weekly'
  labels:
    - 'dependencies'
  commit-message:
    prefix: 'chore(deps)'
  groups:
    all-npm:
      patterns:
        - '*'
```

> **🔄 Human Decision Point**
>
> Ask the user which optional workflows to include (release.yml, stale.yml).
>
> _Agent implementation: Use your platform's user interaction mechanism (e.g., AskUserQuestion in
> Claude Code, input prompts in Gemini CLI, UI dialogs in Cursor/VS Code)._
