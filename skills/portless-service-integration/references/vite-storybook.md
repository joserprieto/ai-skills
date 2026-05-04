# Portless + Node frameworks (Vite, Storybook, Astro, Next)

Canonical patterns for Node-based dev servers behind portless.

## TL;DR

For frameworks that ignore the `PORT` env var (Vite, Astro, React Router, Angular, Expo, React
Native), **portless auto-injects `--port` and `--host` flags** — you don't pass them. For frameworks
that respect `PORT` (Next.js, Express, Nuxt), portless just sets the env var.

No `service-manager.ts` abstraction needed. `portless <name> <cmd>` is a plain CLI invocation —
works directly in Makefile targets or `package.json` scripts.

## Pattern 1: Vite (auto-injected flags)

### In Makefile

```makefile
start: _ensure_deps
	@portless dev.d.ps.myorg vite --profile development
```

Portless sees `vite` in the command, detects it as a framework that ignores `PORT`, and auto-injects
`--port <ephemeral>` and `--host 127.0.0.1` into the final invocation. You don't write those flags.

### In `package.json`

```json
{
  "scripts": {
    "dev": "portless run vite --profile development"
  }
}
```

`portless run` infers the project name from `package.json`'s `name` field. No explicit `<name>`
argument.

### Worktree-aware naming (automatic)

```bash
# On main worktree
portless run vite
# → https://myapp.localhost

# On linked worktree on branch "fix-ui"
portless run vite
# → https://fix-ui.myapp.localhost
```

`portless run` detects git worktrees and prepends the branch name as subdomain. Useful for parallel
development on multiple branches without URL collisions.

## Pattern 2: Storybook

Storybook's `storybook dev` CLI reads `PORT` env var directly:

```makefile
start/storybook: _ensure_deps
	@portless storybook.myapp storybook dev --no-open
```

No `--port` flag needed. Portless sets `PORT`, Storybook picks it up.

Equivalent in `package.json`:

```json
{
  "scripts": {
    "storybook": "portless run storybook dev --no-open"
  }
}
```

## Pattern 3: Next.js / Express / Nuxt (respect `PORT`)

```makefile
start/backend: _ensure_deps
	@portless api.myapp next start
```

Next.js, Express, and Nuxt all read `process.env.PORT` automatically. Just prefix with
`portless <name>`.

## Pattern 4: Multiple profiles (same app, different env)

Your app runs with multiple feature flags or content sets. Use the `PROFILE` convention from
`makefile-service-conventions`:

```makefile
APP     ?= ps
PROFILE ?= development

start: _ensure_deps
	@portless dev.$(PROFILE_INITIAL).$(APP).myorg \
		sh -c 'cd $(APP_DIR) && APP_PROFILE=$(PROFILE) pnpm dev'

# Helper to map profile name to initial
PROFILE_INITIAL := $(shell echo $(PROFILE) | cut -c1)
```

Invocation:

```bash
make start                         # dev.d.ps.myorg.localhost (development)
make start PROFILE=production       # dev.p.ps.myorg.localhost
make start PROFILE=staging          # dev.s.ps.myorg.localhost
```

Each profile gets its own URL, cookies, localStorage, no cross-contamination.

## Pattern 5: Preview (build + serve)

```makefile
build:
	@pnpm build

start/preview: _ensure_deps build
	@portless preview.$(PROFILE_INITIAL).$(APP).myorg \
		sh -c 'cd $(APP_DIR) && pnpm preview'
```

Separate `preview.*` URL from the dev URL so you can run both concurrently (dev with HMR, preview
with built bundles — for verification).

## Pattern 6: Proxying between portless apps (frontend → backend)

When your Vite dev server proxies API requests to another portless app, **set `changeOrigin: true`**
to rewrite the Host header. Otherwise portless routes the request back to the frontend → infinite
loop → `508 Loop Detected` response.

```ts
// vite.config.ts
export default defineConfig({
  server: {
    proxy: {
      '/api': {
        target: 'https://api.myapp.localhost',
        changeOrigin: true, // CRITICAL
        ws: true,
      },
    },
  },
});
```

Same for webpack-dev-server:

```js
devServer: {
  proxy: [{
    context: ["/api"],
    target: "https://api.myapp.localhost",
    changeOrigin: true,
  }],
}
```

## When you need more than plain Makefile targets

If your project has **many services with PID tracking, log rotation, background/foreground modes,
cross-service dependencies**, a custom orchestrator (e.g. `scripts/service-manager.ts` in a
monorepo) may help. But it's not a portless requirement.

Example of when to add an orchestrator:

- 4+ services that must start in sequence
- Logs must be centrally managed with rotation policies
- Background mode + status/tail/stop targets need consistent UX
- Multi-user CI where state files need to be named deterministically

For 1-3 services, plain Makefile targets with direct `portless <name> <cmd>` invocations are simpler
and just as reliable.

## Common mistakes

| Mistake                                                 | Fix                                                             |
| ------------------------------------------------------- | --------------------------------------------------------------- |
| `portless myapp vite --port 3000`                       | Omit `--port`; portless auto-injects for Vite                   |
| `portless myapp next dev --port 3000`                   | Omit `--port`; Next.js reads `PORT` env var                     |
| Writing a service-manager just for portless integration | Not needed; call `portless` directly in Make/npm scripts        |
| Vite proxy without `changeOrigin: true`                 | Set `changeOrigin: true` to avoid `508 Loop Detected`           |
| Same URL for dev and preview                            | Separate `dev.*` and `preview.*` subdomains                     |
| Using `0.0.0.0` host                                    | Portless wants `127.0.0.1`; for Vite/Astro it auto-injects this |
