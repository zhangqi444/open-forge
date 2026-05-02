---
name: bunkerm-project
description: BunkerM recipe for open-forge. All-in-one MQTT broker management platform bundling Eclipse Mosquitto with a web UI, ACL management, message history, anomaly detection, local automation agents, and optional cloud AI (BunkerAI). Single Docker container. Upstream: https://github.com/bunkeriot/BunkerM
---

# BunkerM

An all-in-one, self-hosted MQTT broker management platform. Bundles **Eclipse Mosquitto** with a full web dashboard in a single Docker container — one command to get a production-ready MQTT broker with a management UI, ACL controls, message history, anomaly detection, local automation agents, and optional cloud AI (BunkerAI).

Upstream: <https://github.com/bunkeriot/BunkerM> | Docs: <https://bunkerai.dev/docs>

> Two tiers: **Community** (fully self-hosted, free) and **BunkerAI** (optional cloud AI layer — Telegram/Slack/web chat assistant). The cloud tier requires an API key; leave `BUNKERAI_API_KEY` blank to keep the agent dormant.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host with Docker | Single container; MQTT on `:1900`, web UI on `:2000` |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "MQTT broker host port?" | Default: `1900` |
| preflight | "Web UI host port?" | Default: `2000` |
| security | "MQTT username and password?" | `MQTT_USERNAME` / `MQTT_PASSWORD`; change from defaults |
| security | "Generate JWT_SECRET, API_KEY, AUTH_SECRET?" | All must be changed in production |
| config | "Public URL for the frontend?" | `FRONTEND_URL` — e.g. `http://bunkerm.lan:2000` |
| config | "Behind HTTPS reverse proxy?" | Set `COOKIE_SECURE=true` |
| config (BunkerAI) | "BunkerAI API key?" | Optional; leave blank to disable cloud AI |

## Software-layer concerns

### Image

```
bunkeriot/bunkerm:latest
```

Docker Hub: <https://hub.docker.com/r/bunkeriot/bunkerm>

### Compose

```yaml
services:
  bunkerm:
    image: bunkeriot/bunkerm:latest
    restart: unless-stopped
    ports:
      - "1900:1900"   # MQTT broker
      - "2000:2000"   # Web UI
    volumes:
      - next_data:/nextjs/data             # User accounts and app data
      - mosquitto_data:/var/lib/mosquitto  # Broker clients and ACLs
      - history_data:/var/lib/history      # Message history (SQLite)
    environment:
      # MQTT broker
      - MQTT_BROKER=localhost
      - MQTT_PORT=1900
      - MQTT_USERNAME=bunker               # CHANGE IN PRODUCTION
      - MQTT_PASSWORD=bunker               # CHANGE IN PRODUCTION

      # Security — CHANGE ALL THREE IN PRODUCTION
      - JWT_SECRET=your_jwt_secret_here
      - API_KEY=your_api_key_here
      - AUTH_SECRET=your_auth_secret_here

      # Set true ONLY when behind HTTPS reverse proxy
      - COOKIE_SECURE=false

      # App settings
      - FRONTEND_URL=http://localhost:2000
      - ALLOWED_ORIGINS=*
      - ALLOWED_HOSTS=*
      - RATE_LIMIT_PER_MINUTE=100

      # Logging
      - LOG_LEVEL=INFO

      # BunkerAI (optional — leave blank to keep dormant)
      - BUNKERAI_API_KEY=
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:2000/api/auth/me"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s

volumes:
  next_data:
  mosquitto_data:
  history_data:
```

> Source: upstream docker-compose.yml — <https://github.com/bunkeriot/BunkerM/blob/main/docker-compose.yml>

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `MQTT_BROKER` | `localhost` | MQTT broker hostname (inside container — use `localhost`) |
| `MQTT_PORT` | `1900` | MQTT broker listen port |
| `MQTT_USERNAME` / `MQTT_PASSWORD` | `bunker` / `bunker` | Broker admin credentials — **change in production** |
| `JWT_SECRET` | default value | JWT signing secret — **change in production** |
| `API_KEY` | default value | Internal API key — **change in production** |
| `AUTH_SECRET` | default value | Session auth secret — **change in production** |
| `COOKIE_SECURE` | `false` | Set `true` when behind a TLS reverse proxy |
| `FRONTEND_URL` | `http://localhost:2000` | Public URL of the web UI (used for CORS and redirects) |
| `ALLOWED_ORIGINS` | `*` | CORS allowed origins (restrict in production) |
| `RATE_LIMIT_PER_MINUTE` | `100` | API rate limit per IP |
| `LOG_LEVEL` | `INFO` | Log verbosity |
| `BUNKERAI_API_KEY` | — | BunkerAI cloud API key (leave blank to disable) |

### Persistent volumes

| Volume | Container path | Contents |
|---|---|---|
| `next_data` | `/nextjs/data` | User accounts, web app data |
| `mosquitto_data` | `/var/lib/mosquitto` | Mosquitto clients, ACL (dynamic security plugin) |
| `history_data` | `/var/lib/history` | Message history (SQLite) |

All three are required for data persistence across container restarts and upgrades.

### Features overview

- **Broker Dashboard** — real-time connection and message rate metrics
- **ACL & Client Management** — create/manage MQTT clients, roles, and access control lists via the dynamic security plugin
- **MQTT Explorer** — subscribe to topics and inspect live messages from the web UI
- **Message History & Replay** — SQLite-backed message store with replay support
- **Smart Anomaly Detection** — local statistical engine for detecting unusual broker patterns
- **Agents (Schedulers & Watchers)** — local automation: schedule MQTT publishes and watch for trigger conditions
- **Local LLM (LM Studio)** — connect a locally running LM Studio instance for AI-assisted broker management without cloud access
- **BunkerAI** — optional cloud AI assistant reachable via Telegram, Slack, or web chat (requires API key from <https://bunkerai.dev>)
- **Cloud Bridge Integrations** — connect Mosquitto to AWS IoT, Azure IoT Hub, GCP Pub/Sub, and other cloud MQTT brokers

### Community vs BunkerAI

| Feature | Community (free) | BunkerAI (cloud) |
|---|---|---|
| Mosquitto broker | ✅ | ✅ |
| Web UI | ✅ | ✅ |
| ACL management | ✅ | ✅ |
| Message history | ✅ | ✅ |
| Anomaly detection | ✅ | ✅ |
| Local agents | ✅ | ✅ |
| Local LLM (LM Studio) | ✅ | ✅ |
| Cloud AI assistant | ❌ | ✅ |
| Telegram/Slack bot | ❌ | ✅ |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

All three named volumes persist across upgrades.

## Gotchas

- **Change all default secrets before production deployment** — `MQTT_PASSWORD`, `JWT_SECRET`, `API_KEY`, and `AUTH_SECRET` all ship with insecure defaults that must be replaced.
- **`COOKIE_SECURE=true` requires HTTPS** — setting this on plain HTTP breaks login. Only enable when behind a TLS-terminating reverse proxy.
- **`MQTT_BROKER=localhost`** — BunkerM runs Mosquitto and the management API inside the same container. Do not change this to an external address unless you are running Mosquitto separately.
- **`FRONTEND_URL` must match where you access the UI** — CORS checks use this value. Set it to your actual public URL (including port if non-standard) to avoid browser CORS errors.
- **`extra_hosts: host.docker.internal`** — required for BunkerM to reach services on the Docker host (e.g. a locally running LM Studio). Safe to keep even if not using host-local services.
- **`ALLOWED_ORIGINS=*` is permissive** — restrict to your actual origin domains in production.
- **BunkerAI is opt-in** — leaving `BUNKERAI_API_KEY` blank keeps the cloud agent completely dormant. No outbound cloud connections are made.

## Links

- Upstream README: <https://github.com/bunkeriot/BunkerM>
- Documentation: <https://bunkerai.dev/docs>
- Docker Hub: <https://hub.docker.com/r/bunkeriot/bunkerm>
- Community (Reddit): <https://www.reddit.com/r/BunkerM/>
