# Portless + Python — uvicorn (ASGI)

Canonical pattern for Python HTTP servers behind portless.

## TL;DR

**Do not use `python -m http.server` behind portless.** Use `uvicorn + starlette` (ASGI) — same
stdlib-style simplicity, but implements HTTP/1.1 keep-alive correctly, which modern HTTP/2 proxies
require for upstream connection pooling.

## Why `python -m http.server` breaks behind portless

- Default protocol is **HTTP/1.0** (closes socket after every response)
- `--protocol HTTP/1.1` flag declares HTTP/1.1 in the status line but the stdlib
  `SimpleHTTPRequestHandler` **does not implement real keep-alive** — it still closes the socket
  after each response
- The proxy's upstream connection pool expects keep-alive; stale sockets poison the pool and client
  TLS connections close mid-handshake with `SSL_ERROR_SYSCALL`
- The stdlib module is explicitly documented as "educational, not production-grade"

This is not a Python-vs-Node issue. Python servers like **uvicorn, gunicorn, aiohttp, hypercorn,
tornado** all speak HTTP/1.1 keep-alive correctly. Only the stdlib `http.server` is the problem.

## Canonical pattern: uvicorn + starlette static files

### 1. Dependencies (add to `pyproject.toml`)

```toml
dependencies = [
    "uvicorn[standard]>=0.30",
    "starlette>=0.38",
]
```

`uvicorn[standard]` includes `uvloop` (libuv in C) and `httptools` (C HTTP parser) —
production-grade performance at ~30-40 MB RAM, ~500 ms cold start.

### 2. Minimal ASGI app (`serve_app.py`, 11 lines)

```python
"""ASGI static file server behind portless."""
from pathlib import Path

from starlette.applications import Starlette
from starlette.staticfiles import StaticFiles

ROOT = Path(__file__).parent

app = Starlette(routes=[], debug=False)
app.mount("/", StaticFiles(directory=str(ROOT), html=True), name="static")
```

`html=True` makes it serve `index.html` at `/` automatically (same as nginx's
`try_files $uri /index.html`).

### 3. Makefile target

```makefile
HAS_PORTLESS := $(shell command -v portless 2>/dev/null)
UV ?= uv

serve: _ensure_deps generate
ifdef HAS_PORTLESS
	@portless dashboard.myapp \
		sh -c 'exec $(UV) run uvicorn serve_app:app --host 127.0.0.1 --port "$$PORT" --log-level info'
else
	@$(UV) run uvicorn serve_app:app --host 127.0.0.1 --port 8765
endif
```

Key details:

- **`sh -c 'exec ...'`** because `uvicorn` does not read `$PORT` env var automatically. The shell
  expands `"$PORT"` (injected by portless) and passes it as `--port`. `exec` replaces the shell
  process so Ctrl-C propagates correctly to uvicorn.
- **`--host 127.0.0.1`** matches portless's `HOST=127.0.0.1` contract. Never `localhost` (may
  resolve to `::1`) or `0.0.0.0` (exposes to LAN).
- **`--log-level info`** so you see `Uvicorn running on ...` at startup. `warning` silences startup
  logs and makes debugging harder.

### 4. Test

```bash
make start
# In another terminal:
curl -sS -I https://dashboard.myapp.localhost/
# Expected: HTTP/2 200, x-portless: 1, server: uvicorn
```

## Benefits uvicorn gives for free

- `ETag` headers + `If-None-Match` handling → 304 responses
- `Accept-Ranges: bytes` → range requests (video/PDF streaming)
- Content type detection via `mimetypes`
- Gzip / brotli compression (with `starlette.middleware.gzip.GZipMiddleware`)
- Hot reload with `--reload` flag in development

## If you need dynamic endpoints alongside static files

Extend the Starlette app with routes:

```python
from starlette.applications import Starlette
from starlette.staticfiles import StaticFiles
from starlette.routing import Route
from starlette.responses import JSONResponse

async def health(request):
    return JSONResponse({"ok": True})

app = Starlette(routes=[
    Route("/health", health),
])
app.mount("/", StaticFiles(directory=".", html=True), name="static")
```

## Alternatives to uvicorn (all HTTP/1.1 keep-alive compliant)

- **`aiohttp`** — single-package dep, async, similar footprint
- **`hypercorn`** — ASGI like uvicorn but supports HTTP/3
- **`waitress`** — WSGI (for Flask/Django sync apps), production-grade
- **`gunicorn`** — WSGI with worker pool, standard for Python web deployment

For static file serving, uvicorn+starlette is the lightest modern option. For WSGI apps (Flask,
Django), gunicorn or waitress are appropriate.

## Common mistakes

| Mistake                                         | Fix                                                     |
| ----------------------------------------------- | ------------------------------------------------------- |
| `python -m http.server "$PORT"` behind portless | Use `uvicorn serve_app:app --port "$PORT"`              |
| `python -m http.server --protocol HTTP/1.1`     | Still broken — stdlib lacks real keep-alive             |
| `uvicorn app:app` without `--port "$PORT"`      | uvicorn ignores `$PORT` env var; pass `--port` explicit |
| `uvicorn --host localhost`                      | Use `127.0.0.1` — see main skill                        |
| `uvicorn --host 0.0.0.0` in dev                 | Use `127.0.0.1` — avoids LAN exposure                   |
| `--log-level warning` during setup              | Use `info` to see startup errors                        |
