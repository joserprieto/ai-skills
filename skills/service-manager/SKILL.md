---
name: service-manager
description: >-
  Use when adding background service management to a project that runs dev servers,
  preview servers, or any long-running processes. Also use when user says "service manager",
  "background server", "start/stop services", "PID management", "log rotation", or needs
  Makefile targets for start/stop/status/tail/logs.
license: MIT
metadata:
  author: Jose R. Prieto <hi at joserprieto dot es>
  version: '0.3.0'
  status: STABLE
---

# Service Manager Pattern

Add background service management to any project with PID tracking, health checks, log
rotation, and Makefile integration. Replaces foreground-only `make dev` patterns with
a full start/stop/status/tail DX.

## When to Use

- Project has dev servers that run in foreground and block the terminal
- Need to manage multiple services (dev, preview, etc.) independently
- Want log persistence and rotation for background services
- Need health checks to verify services are actually responding
- Want consistent `make start/stop/status/tail` interface across projects

## When NOT to Use

- Single-command scripts that don't need background management
- Docker/container-managed services (use docker-compose instead)
- Projects already using PM2, systemd, or similar process managers

## Architecture

```
project/
├── Makefile                   # Orchestrates via SM variable
├── .env.example               # Documented config options
├── .env.local                 # User overrides (git-ignored)
├── scripts/
│   └── service-manager.ts     # Core manager (TypeScript, runs via tsx)
├── .state/                    # PID files (git-ignored)
│   └── <service>.pid          # Format: pid:timestamp
└── .logs/                     # Log files with rotation (git-ignored)
    └── <service>.log
```

## Quick Reference

| Command | Effect |
|---------|--------|
| `make start` | Start default service(s) in background |
| `make start/<svc>/fg` | Start in foreground (Ctrl+C to stop) |
| `make stop` | Stop all services (graceful SIGTERM → SIGKILL) |
| `make status` | Show running/stopped with health check |
| `make status/details` | Add PID, uptime, log size, paths |
| `make tail` | `tail -f` all running service logs |
| `make logs` | List log files with sizes |
| `make logs/rotate` | Rotate log files |

## Implementation Steps

### Step 1: Add Dependencies

Add `tsx` to devDependencies for running TypeScript service manager:

```json
{
  "devDependencies": {
    "tsx": "^4.0.0"
  }
}
```

### Step 2: Create `scripts/service-manager.ts`

Use the example file at `examples/service-manager.ts` as a starting point. Adapt:

1. **`getServices()` function** — Define your services with:
   - `name`, `displayName` — identifier and human label
   - `port`, `portEnvVar` — port number and env var name for override
   - `cwd` — working directory for the command
   - `command` — array of command + args (e.g., `['pnpm', 'dev', '--port', '3000']`)
   - `healthUrl` — HTTP URL for health check (use `{port}` placeholder)

2. **`loadEnv()`** — reads `.env.local` (not `.env` to avoid framework conflicts)

3. **Environment variables** — add project-specific config vars at the top

### Step 3: Create `.env.example`

Document all configurable variables with commented defaults. See `examples/.env.example`.

### Step 4: Create/Update Makefile

Key pattern — delegate to service manager via `SM` variable:

```makefile
SM := npx tsx scripts/service-manager.ts

# Load optional .env.local
-include .env.local

# Export env vars to service manager
export VAR1 VAR2 PORT1 PORT2

# Defaults
VAR1 ?= default_value

start: _ensure
	@$(SM) start <service>

stop:
	@$(SM) stop --all

status:
	@$(SM) status

_ensure: node_modules
node_modules: package.json
	@pnpm install
	@touch node_modules
```

### Step 5: Update `.gitignore`

```gitignore
.state/
.logs/
.env.local
```

## Core Service Manager Features

Kept from example (do not remove):

- **PID files** — Format `pid:timestamp` in `.state/<service>.pid`
- **Process tree kill** — `pgrep -P` recursive, SIGTERM then SIGKILL with timeout
- **Port detection** — `lsof -ti tcp:<port>` fallback when PID file stale
- **Health checks** — HTTP GET with 2s timeout via `fetch()`
- **Log rotation** — Size-based rotation with configurable max files
- **Signal handlers** — SIGINT/SIGTERM cleanup for foreground mode
- **Detached spawn** — `detached: true`, `stdio: ['pipe', logFd, logFd]`, `unref()`

## Common Adaptations

| Scenario | Change |
|----------|--------|
| Monorepo (multiple apps) | Add `APPS_DIR`, use `join(APPS_DIR, 'app-name')` for `cwd` |
| Extra env per service | Add `env?: Record<string, string>` to ServiceConfig |
| Build-then-serve | Use `pnpm run preview` script that chains build + serve |
| Conditional flags | Build command array dynamically based on env vars |
| Custom health check | Override `healthUrl` or extend `checkHealth()` |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `.env` instead of `.env.local` | Frameworks read `.env` — use `.env.local` to avoid conflicts |
| Not exporting env vars in Makefile | Add `export VAR1 VAR2` for service manager to see them |
| Missing `_ensure` prerequisite | All service targets need `_ensure` (which depends on `node_modules`) |
| Forgetting `.gitignore` entries | `.state/`, `.logs/`, `.env.local` must be git-ignored |
| Using `&&` in spawn command array | Shell operators don't work in spawn — create a npm script instead |
