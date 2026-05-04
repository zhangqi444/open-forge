# Soketi

Simple, fast, and resilient open-source WebSockets server implementing the Pusher Protocol v7. Drop-in self-hosted replacement for Pusher Channels. Built on uWebSockets.js (C-level performance) — benchmarked at 8.5x Fastify speed. Supports thousands of concurrent connections on under 1 GB RAM. MIT License. 5K+ GitHub stars. Upstream: <https://github.com/soketi/soketi>. Docs: <https://docs.soketi.app>.

> **Maintenance note:** Soketi is actively maintained by Renoki Co. The project also supports Cloudflare Workers deployment (serverless WebSockets via Durable Objects).

## Compatible install methods

Verified against upstream README at <https://github.com/soketi/soketi>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| NPM | `npx @soketi/soketi start` | ✅ | Quickest local test. |
| Docker | `docker run -p 6001:6001 quay.io/soketi/soketi:latest-16-alpine` | ✅ | Containerized server. |
| Docker Compose | Custom compose with Redis for multi-node | Community | Production multi-instance. |
| Helm (Kubernetes) | <https://docs.soketi.app/getting-started/installation/helm> | ✅ | K8s horizontal scaling. |
| Cloudflare Workers | <https://dash.soketi.app/register> | ✅ (hosted) | Serverless edge WebSockets. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app_id | "App ID for your Pusher app (e.g. `app-id`)?" | Free-text | All |
| app_key | "App key (e.g. `app-key`)?" | Free-text | All |
| app_secret | "App secret (e.g. `app-secret` — keep private)?" | Free-text (sensitive) | All |
| port | "Port to run soketi on? (default: 6001)" | Free-text | Optional |
| multi_node | "Run multiple soketi nodes?" | `AskUserQuestion`: `No (single node)` / `Yes (Redis adapter)` | Production |

## Software-layer concerns

### NPM quickstart

```bash
npx @soketi/soketi start
```

Default: binds to `0.0.0.0:6001`. Default app: ID=`app-id`, key=`app-key`, secret=`app-secret`.

### Docker

```bash
docker run -p 6001:6001 -p 9601:9601 \
  quay.io/soketi/soketi:latest-16-alpine
```

- Port `6001` — WebSocket + HTTP API
- Port `9601` — Prometheus metrics endpoint

### Docker Compose (with Redis for multi-node)

```yaml
services:
  soketi:
    image: quay.io/soketi/soketi:latest-16-alpine
    ports:
      - "6001:6001"
      - "9601:9601"
    environment:
      SOKETI_DEFAULT_APP_ID: "my-app-id"
      SOKETI_DEFAULT_APP_KEY: "my-app-key"
      SOKETI_DEFAULT_APP_SECRET: "my-app-secret"
      SOKETI_ADAPTER_DRIVER: redis
      SOKETI_ADAPTER_REDIS_HOST: redis
      SOKETI_ADAPTER_REDIS_PORT: 6379

  redis:
    image: redis:7-alpine
```

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| `SOKETI_DEFAULT_APP_ID` | Default app's ID | `app-id` |
| `SOKETI_DEFAULT_APP_KEY` | Default app's key | `app-key` |
| `SOKETI_DEFAULT_APP_SECRET` | Default app's secret | `app-secret` |
| `SOKETI_PORT` | Port to listen on | `6001` |
| `SOKETI_HOST` | Bind address | `0.0.0.0` |
| `SOKETI_ADAPTER_DRIVER` | Pub/sub adapter | `local` (single node), `redis` (multi-node) |
| `SOKETI_ADAPTER_REDIS_HOST` | Redis host | — |
| `SOKETI_ADAPTER_REDIS_PORT` | Redis port | `6379` |
| `SOKETI_APP_MANAGER_DRIVER` | App storage backend | `array` (memory), `dynamodb`, `mysql`, `postgres` |
| `SOKETI_MAX_CHANNEL_NAME_LENGTH` | Max channel name length | `200` |
| `SOKETI_SSL_CERT` | Path to SSL cert | — |
| `SOKETI_SSL_KEY` | Path to SSL key | — |
| `SOKETI_DEBUG` | Debug logging | `0` |
| `SOKETI_METRICS_SERVER_PORT` | Prometheus metrics port | `9601` |

Full environment variable reference: <https://docs.soketi.app/getting-started/environment-variables>

### App management

By default, soketi uses a single in-memory app (`array` driver). For production with multiple apps, switch to a database driver:

| Driver | `SOKETI_APP_MANAGER_DRIVER` | Notes |
|---|---|---|
| Memory | `array` | Default — single app, no persistence |
| DynamoDB | `dynamodb` | Serverless, AWS-native |
| MySQL | `mysql` | Persistent multi-app support |
| PostgreSQL | `postgres` | Persistent multi-app support |

### Client integration (Pusher-compatible)

Because soketi implements Pusher Protocol v7, use any Pusher client SDK and point it at your server:

```js
// JavaScript (pusher-js)
import Pusher from 'pusher-js';

const pusher = new Pusher('my-app-key', {
  wsHost: 'soketi.example.com',
  wsPort: 6001,
  wssPort: 6001,
  forceTLS: false,          // set true if TLS configured
  enabledTransports: ['ws', 'wss'],
  disableStats: true,
  cluster: 'mt1',           // ignored by soketi but required by pusher-js
});

const channel = pusher.subscribe('my-channel');
channel.bind('my-event', (data) => {
  console.log(data);
});
```

```php
// PHP (Laravel Broadcasting)
// config/broadcasting.php
'pusher' => [
    'driver' => 'pusher',
    'key' => env('PUSHER_APP_KEY'),
    'secret' => env('PUSHER_APP_SECRET'),
    'app_id' => env('PUSHER_APP_ID'),
    'options' => [
        'host' => env('PUSHER_HOST', 'soketi.example.com'),
        'port' => env('PUSHER_PORT', 6001),
        'scheme' => env('PUSHER_SCHEME', 'http'),
        'encrypted' => true,
        'useTLS' => false,
    ],
],
```

### HTTP API (server-side event publishing)

Soketi implements the Pusher HTTP API for publishing events from your backend:

```bash
# Trigger an event
curl -X POST "http://soketi.example.com:6001/apps/my-app-id/events" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-event",
    "data": "{\"message\": \"hello\"}",
    "channel": "my-channel"
  }'
```

### Horizontal scaling

For multiple soketi instances behind a load balancer:
1. Set `SOKETI_ADAPTER_DRIVER=redis` on all nodes
2. All nodes connect to the same Redis instance for pub/sub
3. Put a WebSocket-capable load balancer in front (nginx, HAProxy, Cloudflare)

### Metrics

Prometheus metrics exposed on port `9601` at `/metrics`. Covers active connections, messages sent/received, channels count per app.

## Upgrade procedure

```bash
docker compose pull soketi
docker compose up -d soketi
```

No database migrations needed (unless using MySQL/PostgreSQL app manager — check release notes).

## Gotchas

- **Default credentials are public.** The defaults (`app-id` / `app-key` / `app-secret`) are documented in the README. Change them in any internet-facing deployment.
- **Single-node by default.** The `local` adapter does not sync events between multiple instances. Use `redis` adapter for multi-node.
- **Pusher-js requires `cluster` but soketi ignores it.** You must pass `cluster: 'mt1'` (or any string) to `pusher-js` to avoid a client error — soketi ignores the value.
- **TLS must be handled externally.** Put a reverse proxy (nginx, Caddy) in front for TLS termination. Or set `SOKETI_SSL_CERT` + `SOKETI_SSL_KEY` directly.
- **WebSocket load balancers need sticky sessions.** If using multiple nodes, ensure your load balancer supports WebSocket protocol and, for `local` adapter, sticky sessions. With `redis` adapter, any node can handle any connection.
- **HTTP API auth is HMAC-based.** Server-to-server calls to the HTTP API use Pusher's HMAC-SHA256 signature scheme — use an official Pusher server SDK or compute manually.
- **Memory footprint is very low.** Soketi can hold thousands of connections on <1 GB RAM, making it suitable for low-cost VPS deployments.

## Links

- Upstream: <https://github.com/soketi/soketi>
- Docs: <https://docs.soketi.app>
- Environment variables: <https://docs.soketi.app/getting-started/environment-variables>
- App management: <https://docs.soketi.app/app-management/introduction>
- Pusher Protocol v7: <https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol>
- Helm chart: <https://docs.soketi.app/getting-started/installation/helm>
