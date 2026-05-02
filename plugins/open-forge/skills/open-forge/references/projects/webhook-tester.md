---
name: webhook-tester-project
description: WebHook Tester recipe for open-forge. Self-hosted webhook inspection and debugging tool. Unique URLs per session, customizable responses, real-time WebSocket notifications, ngrok tunneling, Redis or filesystem persistence. Go binary with embedded React UI. Upstream: https://github.com/tarampampam/webhook-tester
---

# WebHook Tester

A self-hosted alternative to webhook.site and requestinspector.com. Generate unique URLs, point any webhook sender at them, and inspect the incoming requests in real time — with full control over the response code, headers, body, and delay. Real-time notifications via WebSockets (no third-party push service needed). Optional ngrok tunneling to expose a local instance to the public internet.

Upstream: <https://github.com/tarampampam/webhook-tester> | Demo: <https://wh.tarampamp.am>

Built with Go (binary + embedded React UI). Multi-arch Docker image based on `scratch`. Runs as an unprivileged user.

## Compatible combos

| Infra | Storage | Notes |
|---|---|---|
| Any Linux host | In-memory (default) | No persistence; cleared on restart — ideal for local debugging |
| Any Linux host | Filesystem (`fs`) | Persists across restarts; single-node |
| Any Linux host | Redis | Persists across restarts; supports multi-instance behind a load balancer |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `8080` |
| preflight | "Storage driver?" | `memory` (default), `fs` (filesystem), or `redis` |
| preflight (Redis) | "Redis address?" | `--storage-driver=redis` + `--redis-addr=redis:6379` |
| preflight (fs) | "Filesystem storage path?" | `--storage-driver=fs` + `--fs-storage-path=/data` |
| config | "Enable ngrok tunneling?" | `--tunnel-driver=ngrok` + `--ngrok-auth-token=<token>` |
| config | "Pre-create static sessions?" | `--auto-create-sessions` for predictable webhook URLs |

## Software-layer concerns

### Image

```
ghcr.io/tarampampam/webhook-tester:2
```

Docker Hub: <https://hub.docker.com/r/tarampampam/webhook-tester>

### Quick start (in-memory, no persistence)

```bash
docker run --rm -p 8080:8080 ghcr.io/tarampampam/webhook-tester:2
```

Open `http://localhost:8080`.

### Compose (in-memory)

```yaml
services:
  webhook-tester:
    image: ghcr.io/tarampampam/webhook-tester:2
    restart: unless-stopped
    ports:
      - "8080:8080"
```

### Compose (filesystem persistence)

```yaml
services:
  webhook-tester:
    image: ghcr.io/tarampampam/webhook-tester:2
    restart: unless-stopped
    ports:
      - "8080:8080"
    command:
      - serve
      - --storage-driver=fs
      - --fs-storage-path=/data
    volumes:
      - webhook-data:/data

volumes:
  webhook-data:
```

### Compose (Redis persistence + multi-instance)

```yaml
services:
  webhook-tester:
    image: ghcr.io/tarampampam/webhook-tester:2
    restart: unless-stopped
    ports:
      - "8080:8080"
    command:
      - serve
      - --storage-driver=redis
      - --pubsub-driver=redis
      - --redis-addr=redis:6379
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    restart: unless-stopped

volumes:
  redis-data:
```

> Source: upstream README — <https://github.com/tarampampam/webhook-tester>

### Key CLI flags / environment variables

| Flag | Env var | Default | Purpose |
|---|---|---|---|
| `--storage-driver` | `STORAGE_DRIVER` | `memory` | `memory`, `fs`, or `redis` |
| `--pubsub-driver` | `PUBSUB_DRIVER` | `memory` | `memory` or `redis` (required for multi-instance WebSocket) |
| `--redis-addr` | `REDIS_ADDR` | `127.0.0.1:6379` | Redis address (when using Redis drivers) |
| `--fs-storage-path` | `FS_STORAGE_PATH` | `/tmp/webhook-tester` | Filesystem storage path |
| `--tunnel-driver` | `TUNNEL_DRIVER` | — | `ngrok` to enable tunneling |
| `--ngrok-auth-token` | `NGROK_AUTH_TOKEN` | — | ngrok auth token |
| `--auto-create-sessions` | `AUTO_CREATE_SESSIONS` | `false` | Pre-create sessions for static URLs |
| `--max-request-body-size` | `MAX_REQUEST_BODY_SIZE` | — | Max body size for captured requests |

### Storage drivers

| Driver | Persistence | Multi-instance | Use case |
|---|---|---|---|
| `memory` | ❌ (cleared on restart) | ❌ | Local debugging; ephemeral inspection |
| `fs` | ✅ | ❌ | Single-node with persistence between restarts |
| `redis` | ✅ | ✅ | Multi-instance, high-availability, or load-balanced deployments |

### Pub/Sub drivers

WebSocket real-time notifications use a separate pub/sub driver:
- `memory` — single instance only
- `redis` — required when running multiple instances behind a load balancer

When using Redis for storage, also set `--pubsub-driver=redis` to keep WebSocket notifications consistent across instances.

### ngrok tunneling

Expose a locally running instance to the public internet without port forwarding:

```yaml
command:
  - serve
  - --tunnel-driver=ngrok
  - --ngrok-auth-token=your_ngrok_token
```

WebHook Tester manages the ngrok tunnel automatically — no separate ngrok binary or container needed. The public URL is displayed in the UI. Useful for testing webhooks from GitHub, Stripe, Shopify, etc. against a local instance.

### Static / pre-defined sessions

Use `--auto-create-sessions` to pre-create sessions with predictable webhook URLs. Useful when you need a stable URL that survives app restarts (pair with filesystem or Redis storage for full persistence).

### Customizable webhook responses

For each session, configure:
- HTTP response status code
- Response `Content-Type` header
- Response body content
- Response delay (milliseconds)

This lets you simulate specific API responses for testing how your service handles different upstream behaviors.

### Health check

Liveness probe available at `/healthz`.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

With `memory` storage, all captured requests are lost on restart (by design). With `fs` or `redis`, data persists.

## Gotchas

- **Memory storage is ephemeral by design** — all captured requests and sessions are lost when the container restarts. Use `fs` or `redis` if you need persistence.
- **Multi-instance requires Redis for both storage and pub/sub** — using `--storage-driver=redis` without `--pubsub-driver=redis` means WebSocket notifications may not work correctly across instances.
- **ngrok token is required for tunneling** — get a free token at <https://ngrok.com>. The tunnel URL changes on each restart (upgrade to a paid ngrok plan for a stable subdomain).
- **Runs as unprivileged user** — the image runs as a non-root user. Volume mounts for `fs` storage must be writable by that user (or use a named Docker volume).
- **Demo instance is limited** — the public demo at <https://wh.tarampamp.am> has restrictions and no persistence; use a self-hosted instance for production webhook testing.
- **`--auto-create-sessions` only guarantees a stable URL if storage persists** — with `memory` storage, sessions are recreated on restart with the same names but empty history.

## Links

- Upstream README (full CLI reference): <https://github.com/tarampampam/webhook-tester>
- Demo: <https://wh.tarampamp.am>
- GHCR image: <https://github.com/users/tarampampam/packages/container/package/webhook-tester>
- Docker Hub: <https://hub.docker.com/r/tarampampam/webhook-tester>
