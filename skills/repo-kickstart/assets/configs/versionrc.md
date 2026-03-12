#### .versionrc.js — Versioning and Changelog Config

```javascript
/**
 * Configuration for commit-and-tag-version (formerly standard-version).
 *
 * Bump files : .semver, Makefile, pyproject.toml (if Python project)
 * Changelog  : CHANGELOG.md  (via Handlebars templates in .changelog-templates/)
 * Repo       : https://github.com/OWNER/PROJECT
 *
 * Usage:
 *   npx commit-and-tag-version                # auto-detect bump
 *   npx commit-and-tag-version --release-as minor
 *   npx commit-and-tag-version --dry-run
 */

const { readFileSync } = require('fs');
const { resolve } = require('path');

const tpl = (name) => readFileSync(resolve(__dirname, '.changelog-templates', name), 'utf8');

const config = {
  // ── Tag & commit ────────────────────────────────────────────────────
  header:
    '# Changelog\n\nAll notable changes to **PROJECT** will be documented in this file.\n\nThe format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).\n',
  tagPrefix: 'v',
  commitUrlFormat: 'https://github.com/OWNER/PROJECT/commit/{{hash}}',
  compareUrlFormat: 'https://github.com/OWNER/PROJECT/compare/{{previousTag}}...{{currentTag}}',
  issueUrlFormat: 'https://github.com/OWNER/PROJECT/issues/{{id}}',
  userUrlFormat: 'https://github.com/{{user}}',
  releaseCommitMessageFormat: 'chore(release): {{currentTag}}',

  // ── Source of truth for reading the current version ─────────────────
  packageFiles: [
    {
      filename: '.semver',
      type: 'plain-text',
    },
  ],

  // ── Handlebars templates (loaded as strings) ──────────────────────
  writerOpts: {
    mainTemplate: tpl('template.hbs'),
    headerPartial: tpl('header.hbs'),
    commitPartial: tpl('commit.hbs'),
    footerPartial: tpl('footer.hbs'),
  },

  // ── Conventional-commit types shown in the CHANGELOG ────────────────
  types: [
    { type: 'feat', section: 'Features' },
    { type: 'fix', section: 'Bug Fixes' },
    { type: 'perf', section: 'Performance Improvements' },
    { type: 'revert', section: 'Reverts' },
    { type: 'docs', section: 'Documentation', hidden: false },
    { type: 'style', section: 'Styles', hidden: true },
    { type: 'chore', section: 'Miscellaneous Chores', hidden: true },
    { type: 'refactor', section: 'Code Refactoring', hidden: false },
    { type: 'test', section: 'Tests', hidden: true },
    { type: 'build', section: 'Build System', hidden: false },
    { type: 'ci', section: 'Continuous Integration', hidden: true },
  ],

  // ── Files that contain the version string to bump ───────────────────
  bumpFiles: [
    {
      filename: '.semver',
      type: 'plain-text',
    },
    {
      filename: 'Makefile',
      updater: {
        readVersion(contents) {
          const match = contents.match(/^VERSION\s*:=\s*(\S+)/m);
          if (!match) {
            throw new Error('Could not find VERSION in Makefile');
          }
          return match[1];
        },
        writeVersion(contents, version) {
          return contents.replace(/^(VERSION\s*:=\s*)\S+/m, `$1${version}`);
        },
      },
    },
    // ── Python projects: uncomment to bump pyproject.toml ──────────────
    // IMPORTANT: Also add pyproject.toml to RELEASE_FILES in Makefile!
    // {
    //   filename: 'pyproject.toml',
    //   updater: {
    //     readVersion(contents) {
    //       const match = contents.match(/^version\s*=\s*"([^"]+)"/m);
    //       if (!match) {
    //         throw new Error('Could not find version in pyproject.toml');
    //       }
    //       return match[1];
    //     },
    //     writeVersion(contents, version) {
    //       return contents.replace(/^(version\s*=\s*")[^"]+(")/m, `$1${version}$2`);
    //     },
    //   },
    // },
  ],
};

module.exports = config;
```

**Why this design:**

- **`.semver` plain-text over `package.json` version** — Works for non-Node projects (Python, Go,
  shell-only). The `.semver` file contains just `0.1.0` — no JSON parsing needed, readable by any
  tool, and `cat .semver` is all you need in a shell script.
- **`--skip.commit --skip.tag`** — `commit-and-tag-version` runs git via Node `child_process`, which
  doesn't respect local PATH or git hooks (e.g., your `.githooks/pre-commit` data leak detector).
  Manual control from the Makefile is safer — you see exactly what gets committed and tagged.
- **Custom Makefile updater** — The `readVersion`/`writeVersion` regex pair bumps `VERSION := X.Y.Z`
  in the Makefile. This keeps the Makefile version in sync without a second source of truth.
- **Extending for Python projects** — Uncomment the `pyproject.toml` entry in `bumpFiles`. The
  regex uses the `/m` (multiline) flag in BOTH `readVersion` and `writeVersion` — this is critical
  because `version =` is not at the start of the file. Also add `pyproject.toml` to `RELEASE_FILES`
  in the Makefile.
- **Do NOT use `--first-release`** — It skips the version bump entirely (stays at `0.0.0`). For the
  first release, use `--release-as minor` to bump `0.0.0 → 0.1.0`.
- **Empty `CHANGELOG.md` for initial commit** — The `header` property in this config defines the
  CHANGELOG header. If the CHANGELOG file already has a header, it gets duplicated on every release.
