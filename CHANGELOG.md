# Changelog

All notable changes to **AI Skills** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- **repo-kickstart**: Audit improvements (v0.5.0)
  - Replaced agent-specific `AskUserQuestion` calls with agent-agnostic Human Decision Points
  - Added prerequisites table
  - Changed author to "AI Skills Contributors"
  - Restructured for progressive disclosure per Agent Skills spec (<500 lines target):
    - Extracted 12 documentation templates to `assets/templates/`
    - Extracted 8 configuration templates to `assets/configs/`
    - Extracted 6 CI/CD references to `assets/ci/`
    - Extracted release pipeline and data leak prevention guides to `references/`
    - Reduced SKILL.md from ~1950 to ~310 lines

## 0.1.0 (2026-02-18)

### Features

- Initial project infrastructure with CI/CD, linting, and release automation
- **repo-kickstart** skill — Professional OSS repository setup with GitHub Actions, linting, releases,
  and documentation
