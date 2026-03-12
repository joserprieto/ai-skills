# Semantic Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/).

## Version Format

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

Examples:

- `1.0.0` - First stable release
- `1.2.3` - Patch release
- `2.0.0-alpha.1` - Alpha prerelease
- `2.0.0-rc.1` - Release candidate

## Version Source

The single source of truth for version is the `.semver` file at the project root:

```bash
cat .semver
# 0.1.0
```

This file is automatically updated by `commit-and-tag-version` during releases.

## Version Bumping Rules

### MAJOR (X.0.0)

Increment when making **incompatible API changes**:

- Breaking changes to public interfaces
- Removing or renaming public APIs
- Changing data formats in incompatible ways

```bash
make release/major
```

### MINOR (x.Y.0)

Increment when adding **backwards-compatible functionality**:

- New features
- New API endpoints
- Deprecating features (without removing)

```bash
make release/minor
```

### PATCH (x.y.Z)

Increment for **backwards-compatible bug fixes**:

- Bug fixes
- Performance improvements
- Documentation updates
- Internal refactoring

```bash
make release/patch
```

## Prerelease Versions

For unstable releases before a major version:

```bash
# Alpha (early testing)
make release/prerelease PRE=alpha
# Result: 1.0.0-alpha.0

# Beta (feature complete, testing)
make release/prerelease PRE=beta
# Result: 1.0.0-beta.0

# Release candidate (final testing)
make release/prerelease PRE=rc
# Result: 1.0.0-rc.0
```

## Git Tags

Releases are tagged with `v` prefix:

```
v0.1.0
v1.0.0
v1.0.0-alpha.1
```

## Development Versions

During active development (before 1.0.0):

- API may change without major version bump
- Use minor for features, patch for fixes
- Document breaking changes in CHANGELOG

## Related

- [commits.md](./commits.md) - Commit message format
- [changelog.md](./changelog.md) - CHANGELOG generation
- [releases.md](./releases.md) - Release workflow
