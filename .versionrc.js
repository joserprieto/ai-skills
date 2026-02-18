/**
 * Configuration for commit-and-tag-version (formerly standard-version).
 *
 * Bump files : .semver, Makefile
 * Changelog  : CHANGELOG.md  (via Handlebars templates in .changelog-templates/)
 * Repo       : https://github.com/joserprieto/ai-skills
 *
 * Usage:
 *   npx commit-and-tag-version                # auto-detect bump
 *   npx commit-and-tag-version --release-as minor
 *   npx commit-and-tag-version --dry-run
 */

const { readFileSync } = require("fs");
const { resolve } = require("path");

const tpl = (name) =>
  readFileSync(resolve(__dirname, ".changelog-templates", name), "utf8");

const config = {
  // ── Tag & commit ────────────────────────────────────────────────────
  header:
    "# Changelog\n\nAll notable changes to **AI Skills** will be documented in this file.\n\nThe format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).\n",
  tagPrefix: "v",
  commitUrlFormat:
    "https://github.com/joserprieto/ai-skills/commit/{{hash}}",
  compareUrlFormat:
    "https://github.com/joserprieto/ai-skills/compare/{{previousTag}}...{{currentTag}}",
  issueUrlFormat:
    "https://github.com/joserprieto/ai-skills/issues/{{id}}",
  userUrlFormat: "https://github.com/{{user}}",
  releaseCommitMessageFormat: "chore(release): {{currentTag}}",

  // ── Source of truth for reading the current version ─────────────────
  packageFiles: [
    {
      filename: ".semver",
      type: "plain-text",
    },
  ],

  // ── Handlebars templates (loaded as strings) ──────────────────────
  writerOpts: {
    mainTemplate: tpl("template.hbs"),
    headerPartial: tpl("header.hbs"),
    commitPartial: tpl("commit.hbs"),
    footerPartial: tpl("footer.hbs"),
  },

  // ── Conventional-commit types shown in the CHANGELOG ────────────────
  types: [
    { type: "feat", section: "Features" },
    { type: "fix", section: "Bug Fixes" },
    { type: "perf", section: "Performance Improvements" },
    { type: "revert", section: "Reverts" },
    { type: "docs", section: "Documentation", hidden: false },
    { type: "style", section: "Styles", hidden: true },
    { type: "chore", section: "Miscellaneous Chores", hidden: true },
    { type: "refactor", section: "Code Refactoring", hidden: false },
    { type: "test", section: "Tests", hidden: true },
    { type: "build", section: "Build System", hidden: false },
    { type: "ci", section: "Continuous Integration", hidden: true },
  ],

  // ── Files that contain the version string to bump ───────────────────
  bumpFiles: [
    {
      filename: ".semver",
      type: "plain-text",
    },
    {
      filename: "Makefile",
      updater: {
        readVersion(contents) {
          const match = contents.match(/^VERSION\s*:=\s*(\S+)/m);
          if (!match) {
            throw new Error("Could not find VERSION in Makefile");
          }
          return match[1];
        },
        writeVersion(contents, version) {
          return contents.replace(
            /^(VERSION\s*:=\s*)\S+/m,
            `$1${version}`
          );
        },
      },
    },
  ],
};

module.exports = config;
