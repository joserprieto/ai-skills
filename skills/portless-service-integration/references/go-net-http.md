# Portless + Go (`net/http`)

Canonical pattern for Go HTTP services behind portless.

## TL;DR

Go's stdlib `net/http` package speaks HTTP/1.1 with keep-alive **by default**. Drop-in compatible
with portless. Read `PORT` and `HOST` env vars in `main()` and bind the listener; portless does the
rest.

## Minimal server

```go
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
)

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }
    host := os.Getenv("HOST")
    if host == "" {
        host = "127.0.0.1"
    }
    addr := host + ":" + port

    mux := http.NewServeMux()
    mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintln(w, "ok")
    })
    mux.Handle("/", http.FileServer(http.Dir("./public")))

    log.Printf("listening on http://%s", addr)
    if err := http.ListenAndServe(addr, mux); err != nil {
        log.Fatal(err)
    }
}
```

Key points:

- **`os.Getenv("PORT")`** — portless injects this
- **`os.Getenv("HOST")`** — always `127.0.0.1` per portless contract
- **Fallbacks** — when not run under portless, still usable
- **`http.ListenAndServe`** — HTTP/1.1 keep-alive default; no configuration needed

## Makefile target

```makefile
start/backend: _ensure_deps
	@portless api.myapp.myorg go run ./cmd/server
```

Or with a pre-built binary:

```makefile
build/backend:
	@cd packages/backend && go build -o bin/server ./cmd/server

start/backend: build/backend
	@portless api.myapp.myorg ./packages/backend/bin/server
```

Portless sets `PORT` and `HOST` env vars, launches the binary, registers the route. Access via
`https://api.myapp.myorg.localhost/`.

## Explicit `Server` struct for production-like settings

When you want explicit timeouts (recommended for any non-trivial server):

```go
srv := &http.Server{
    Addr:         host + ":" + port,
    Handler:      mux,
    ReadTimeout:  15 * time.Second,
    WriteTimeout: 30 * time.Second,
    IdleTimeout:  120 * time.Second,
}
log.Fatal(srv.ListenAndServe())
```

`IdleTimeout` controls how long the server holds keep-alive connections. Portless proxy pools
upstream connections, so a value like 120s is appropriate — matches what modern reverse proxies
(nginx, caddy) use.

## Graceful shutdown (for Ctrl-C / portless lifecycle)

Portless sends `SIGTERM` when you kill the parent process. Handle it so in-flight requests complete:

```go
import (
    "context"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    // ... srv setup ...

    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()

    stop := make(chan os.Signal, 1)
    signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
    <-stop

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    if err := srv.Shutdown(ctx); err != nil {
        log.Fatalf("shutdown error: %v", err)
    }
}
```

## HTTP/2 upstream (rarely needed)

Portless proxies HTTP/2 to the browser but uses HTTP/1.1 to connect to upstream (standard reverse
proxy pattern). You don't need to enable HTTP/2 in your Go server — portless terminates HTTP/2 at
the proxy edge.

If you want HTTP/2 within the server process for internal reasons, use `golang.org/x/net/http2` with
`h2c` (HTTP/2 cleartext):

```go
import (
    "golang.org/x/net/http2"
    "golang.org/x/net/http2/h2c"
)

h2s := &http2.Server{}
srv := &http.Server{
    Addr:    addr,
    Handler: h2c.NewHandler(mux, h2s),
}
```

But for portless integration this is overkill — HTTP/1.1 is the expected upstream protocol.

## WebSocket support

Go's stdlib doesn't include WebSocket; use `gorilla/websocket` or `nhooyr.io/websocket`. Portless
proxies WebSocket upgrades transparently — no special config on your side beyond what you'd normally
write.

```go
import "nhooyr.io/websocket"

func wsHandler(w http.ResponseWriter, r *http.Request) {
    c, err := websocket.Accept(w, r, nil)
    if err != nil {
        return
    }
    defer c.Close(websocket.StatusInternalError, "")
    // ... handle messages ...
}
```

Access via `wss://api.myapp.myorg.localhost/ws` automatically (portless upgrades `https://` →
`wss://`).

## Common mistakes

| Mistake                                               | Fix                                                                          |
| ----------------------------------------------------- | ---------------------------------------------------------------------------- |
| `http.ListenAndServe(":"+port, ...)` (all interfaces) | Bind to `"127.0.0.1:"+port` explicit                                         |
| `http.ListenAndServe("0.0.0.0:"+port, ...)`           | Same — use `127.0.0.1`                                                       |
| Hardcoding `8080` instead of reading `$PORT`          | `os.Getenv("PORT")` with fallback                                            |
| Not handling SIGTERM                                  | Implement graceful shutdown — `Ctrl-C` may leave stale connections otherwise |
| Setting HTTP/2 ALPN on the server                     | Unnecessary; portless handles HTTP/2 at proxy edge                           |
| Long `WriteTimeout` that exceeds `IdleTimeout`        | Order matters: `IdleTimeout > WriteTimeout > ReadTimeout`                    |
