#### package.json (tooling only)

```json
{
  "private": true,
  "description": "Release and linting tooling for PROJECT",
  "scripts": {
    "release": "commit-and-tag-version --skip.commit --skip.tag",
    "release:dry-run": "commit-and-tag-version --dry-run",
    "lint:md": "markdownlint-cli2 '**/*.md'",
    "lint:md:fix": "markdownlint-cli2 --fix '**/*.md'",
    "format": "prettier --write '**/*.{md,json,yml,yaml}'",
    "format:check": "prettier --check '**/*.{md,json,yml,yaml}'"
  },
  "devDependencies": {
    "commit-and-tag-version": "^12.5.0",
    "markdownlint-cli2": "^0.17.0",
    "prettier": "^3.4.2"
  }
}
```
