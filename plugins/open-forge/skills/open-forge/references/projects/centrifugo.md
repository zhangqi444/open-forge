# Centrifugo

Scalable real-time messaging server. Centrifugo delivers messages to application users over WebSocket, HTTP-streaming, Server-Sent Events (SSE), gRPC, and WebTransport. It's a language-agnostic PUB/SUB server suited for chat apps, live comments, multiplayer games, real-time dashboards, and collaborative tools. Upstream: <https://github.com/centrifugal/centrifugo>. Docs: <https://centrifugal.dev>.

Centrifugo listens on port `8000` by default (HTTP API + WebSocket + SSE endpoints). It includes an embedded admin web UI at `/admin`. It's a stateless single binary that scales out with Redis (or Redis Cluster, Valkey, KeyDB, Nats, etc.) as the broker/presence backend.

## Compatible install methods

Verified against upstream docs at <https://centrifugal.dev/docs/getting-started/installation>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/centrifugo/centrifugo> | ✅ | Easiest deploy. Official Docker image `centrifugo/centrifugo`. |
| Binary (Linux/macOS/Windows) | <https://github.com/centrifugal/centrifugo/releases> | ✅ | Direct install on host. |
| Kubernetes / Helm | <https://centrifugal.dev/docs/getting-started/installation#kubernetes> | ✅ | Production Kubernetes. Official Helm chart available. |
| Package managers (brew, apt via packagecloud) | <https://centrifugal.dev/docs/getting-started/installation#os-packages> | ✅ | Linux package install. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| secrets | "token_hmac_secret_key (JWT signing secret)?" | Free-text (generate random string) | All |
| secrets | "admin_password and admin_secret?" | Free-text (sensitive) | All |
| broker | "Scale-out broker?" | `AskUserQuestion`: `In-memory (single node)` / `Redis` / `Nats` | Production |
| port | "Port for Centrifugo?" | Number (default 8000) | All |

## Software-layer concerns

### Minimal config (`config.json` or env vars)

Centrifugo reads config from a JSON/YAML/TOML file or environment variables (prefix: `CENTRIFUGO_`):

```json
{
  "token_hmac_secret_key": "your-strong-secret-key",
  "admin": true,
  "admin_password": "your-admin-password",
  "admin_secret": "your-admin-secret",
  "api_key": "your-api-key",
  "allowed_origins": ["https://app.example.com"]
}
```

All config keys map to env vars: `token_hmac_secret_key` → `CENTRIFUGO_TOKEN_HMAC_SECRET_KEY`.

### Docker Compose (single node, in-memory broker)

```yaml
services:
  centrifugo:
    image: centrifugo/centrifugo:latest
    command: centrifugo -c /centrifugo/config.json
    ports:
      - "8000:8000"
    volumes:
      - ./centrifugo:/centrifugo
    environment:
      CENTRIFUGO_TOKEN_HMAC_SECRET_KEY: "${CENTRIFUGO_TOKEN_HMAC_SECRET_KEY}"
      CENTRIFUGO_ADMIN_PASSWORD: "${CENTRIFUGO_ADMIN_PASSWORD}"
      CENTRIFUGO_ADMIN_SECRET: "${CENTRIFUGO_ADMIN_SECRET}"
      CENTRIFUGO_API_KEY: "${CENTRIFUGO_API_KEY}"
    restart: unless-stopped
    ulimits:
      nofile:
        soft: 65535
        hard: 65535
```

### Docker Compose (with Redis broker for scale-out)

```yaml
services:
  centrifugo:
    image: centrifugo/centrifugo:latest
    command: centrifugo -c /centrifugo/config.json
    ports:
      - "8000:8000"
    volumes:
      - ./centrifugo:/centrifugo
    environment:
      CENTRIFUGO_TOKEN_HMAC_SECRET_KEY: "${CENTRIFUGO_TOKEN_HMAC_SECRET_KEY}"
      CENTRIFUGO_ADMIN_PASSWORD: "${CENTRIFUGO_ADMIN_PASSWORD}"
      CENTRIFUGO_ADMIN_SECRET: "${CENTRIFUGO_ADMIN_SECRET}"
      CENTRIFUGO_API_KEY: "${CENTRIFUGO_API_KEY}"
      CENTRIFUGO_BROKER: redis
      CENTRIFUGO_REDIS_ADDRESS: redis:6379
    depends_on:
      - redis
    restart: unless-stopped
    ulimits:
      nofile:
        soft: 65535
        hard: 65535

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  redis_data:
```

### Key config fields

| Field | Purpose | Notes |
|---|---|---|
| `token_hmac_secret_key` | HMAC secret for JWT auth tokens | Required. Keep secret. |
| `api_key` | Server-side API key | Used by your backend to publish messages to Centrifugo. |
| `admin` | Enable admin UI | Set to `true` to enable the `/admin` panel. |
| `admin_password` / `admin_secret` | Admin panel auth | Set both to protect the admin UI. |
| `allowed_origins` | CORS origins for WebSocket connections | List your frontend domain(s). |
| `broker` | Pub/sub broker (`memory`, `redis`, `nats`) | Use `redis` for multi-node deployments. |

### Architecture

Your backend publishes events to Centrifugo via its HTTP or gRPC API. Centrifugo fans out messages to all subscribed clients. Your frontend uses a Centrifugo SDK (JavaScript, iOS, Android, etc.) to connect and subscribe to channels.

```
[Your Backend] --HTTP/gRPC API--> [Centrifugo] --WebSocket/SSE--> [Browser/App Clients]
```

## Upgrade procedure

1. Pull the new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Centrifugo is stateless (state is in Redis/memory), so no migration steps needed for minor/patch upgrades.
4. For major versions, check the [migration guide](https://centrifugal.dev/docs/getting-started/migration) for breaking changes.

## Gotchas

- **Centrifugo is a transport layer, not a full chat backend.** It handles delivery of messages — your application backend handles business logic (storing messages, auth, etc.).
- **Raise `ulimits: nofile`.** Each connected client is a file descriptor. The default OS limit (often 1024) will bottleneck you at low connection counts. Set to at least 65535.
- **In-memory broker is single-node only.** To run multiple Centrifugo instances behind a load balancer, use Redis (or Nats) as the broker.
- **JWT auth is client-side.** Your backend issues JWT tokens to clients; clients present them to Centrifugo on connect. Centrifugo verifies the token but does NOT call your backend on each connection (unless you use the proxy mode).
- **History is in-memory by default.** Channel history (for message recovery on reconnect) uses memory by default. For persistence across restarts, configure `history_recover` with a Redis history storage.

## Links

- Upstream: <https://github.com/centrifugal/centrifugo>
- Docs: <https://centrifugal.dev>
- Installation: <https://centrifugal.dev/docs/getting-started/installation>
- Client SDKs: <https://centrifugal.dev/docs/transports/client-sdk>
- Docker Hub: <https://hub.docker.com/r/centrifugo/centrifugo>
- Helm chart: <https://github.com/centrifugal/centrifugo/tree/master/misc/helm>
