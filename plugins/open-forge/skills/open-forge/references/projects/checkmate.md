---
name: Checkmate
description: Open-source uptime + infrastructure monitoring. HTTP/ping/port/Docker/SSL/game-server checks, CPU/RAM/disk via "Capture" agent, status pages, incident tracking. Stress-tested to 1000+ monitors. Node.js + MongoDB + Redis. AGPL-3.0.
---

# Checkmate

Checkmate (by BlueWave Labs) is an open-source uptime + infrastructure monitoring tool — the philosophical neighbor of Uptime Kuma and Gatus, with an added trick: it has a **Capture** agent you install on servers to report back CPU/RAM/disk/temperature metrics. So instead of just "is the URL responsive?", Checkmate also answers "what's happening INSIDE the servers?"

Tested with 1000+ active monitors without performance issues. Small memory footprint (upstream quotes: Node.js ~20 MB, MongoDB 398 MB, Redis 15 MB for 323 monitors/minute).

Features:

- **Uptime monitoring** — HTTP, Ping, Port, Docker container, SSL certs, game servers, page speed
- **Infrastructure monitoring** — CPU, RAM, disk (with selective mountpoint monitoring), network, temperature (via Capture agent)
- **Status pages** — 4 themes; public/private
- **Scheduled maintenance windows** — suppress alerts during planned work
- **JSON-query monitoring** — extract value from JSON API and assert
- **Multi-channel notifications** — email, webhook, Discord, Slack, PagerDuty, Matrix, MS Teams, Telegram, Pushover, Twilio (SMS)
- **Incident timeline** — auto-created on state change
- **Multi-language UI** — 16+ locales including Arabic, Chinese (S/T), Czech, English, Finnish, French, German, Japanese, Portuguese (BR), Russian, Spanish, Thai, Turkish, Ukrainian, Vietnamese

- Upstream repo: <https://github.com/bluewave-labs/checkmate>
- Capture agent repo: <https://github.com/bluewave-labs/capture>
- Website: <https://checkmate.so>
- Docs: <https://checkmate.so/docs>
- Demo: <https://demo.checkmate.so> (user `demouser@demo.com` / password `Demouser1!`)
- PikaPods: <https://www.pikapods.com/pods?run=checkmate>
- Helm chart: <https://github.com/bluewave-labs/Checkmate/tree/main/charts/helm/checkmate>

## Architecture in one minute

- **Node.js** server (Express-like) + **React + MUI** frontend
- **MongoDB** — operational data (monitors, incidents, users)
- **Redis** — caching + pub/sub
- **Capture** agent (optional, written in Go) — runs on servers; reports hardware metrics back to Checkmate
- **Port 52345 (server default)** / **5173 (frontend dev)**; single port in combined-image prod
- **Multi-language** — frontend baked + i18n runtime

## Compatible install methods

| Infra        | Runtime                                              | Notes                                                              |
| ------------ | ---------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM    | Docker Compose (upstream-provided)                     | **Recommended** — server + client + MongoDB + Redis               |
| Kubernetes   | **Official Helm chart**                                  | <https://github.com/bluewave-labs/Checkmate/tree/main/charts/helm>       |
| Raspberry Pi | Docker armv7/arm64                                       | Supported                                                                 |
| PaaS         | Coolify / Elestio / Sive Host / Cloudzy / PikaPods         | 1-click options                                                                |
| Native       | Node.js + MongoDB + Redis (dev)                           | See repo docs                                                                      |

## Inputs to collect

| Input                   | Example                              | Phase     | Notes                                                        |
| ----------------------- | ------------------------------------ | --------- | ------------------------------------------------------------ |
| `CLIENT_HOST`           | `https://status.example.com`          | URL       | Public-facing URL                                                 |
| `DB_CONNECTION_STRING`  | `mongodb://mongo:27017/checkmate`     | DB        | MongoDB 6+ recommended                                                |
| `REDIS_URL`             | `redis://redis:6379`                   | Cache     | Required                                                                   |
| `JWT_SECRET`            | `openssl rand -hex 64`                 | Security  | Session signing                                                                  |
| `SYSTEM_EMAIL_*`        | SMTP                                    | Email     | Notifications + user invites                                                         |
| Admin user              | via first-run registration               | Bootstrap | Race risk — close registration after first admin                                         |
| TLS                     | Let's Encrypt                            | Security  | Required for PWA + Capture agent auth                                                          |
| Capture agent API key   | generated in Checkmate per-monitor        | Infra     | Paste into Capture's config on the remote server                                                    |

## Install via Docker Compose

Upstream compose (trimmed):

```yaml
services:
  mongodb:
    image: mongo:6
    container_name: checkmate-mongo
    restart: unless-stopped
    volumes:
      - checkmate-mongo:/data/db
    command: ["--bind_ip_all", "--quiet"]

  redis:
    image: redis:7-alpine
    container_name: checkmate-redis
    restart: unless-stopped
    volumes:
      - checkmate-redis:/data

  server:
    image: ghcr.io/bluewave-labs/checkmate-backend:latest    # pin to version
    container_name: checkmate-server
    restart: unless-stopped
    depends_on: [mongodb, redis]
    environment:
      DB_CONNECTION_STRING: mongodb://mongodb:27017/checkmate
      REDIS_URL: redis://redis:6379
      JWT_SECRET: <openssl rand -hex 64>
      CLIENT_HOST: https://status.example.com
      SYSTEM_EMAIL_HOST: smtp.example.com
      SYSTEM_EMAIL_PORT: "587"
      SYSTEM_EMAIL_ADDRESS: alerts@example.com
      SYSTEM_EMAIL_PASSWORD: <smtp-pass>
      SYSTEM_EMAIL_TLS_SERVICE_PROVIDER: gmail
    ports:
      - "52345:52345"

  client:
    image: ghcr.io/bluewave-labs/checkmate:latest
    container_name: checkmate-client
    restart: unless-stopped
    depends_on: [server]
    ports:
      - "80:80"
    environment:
      UPTIME_APP_API_BASE_URL: https://api.status.example.com/api/v1

volumes:
  checkmate-mongo:
  checkmate-redis:
```

Front with Caddy/Traefik/nginx terminating TLS; route `status.example.com` → client, `api.status.example.com` → server.

## Install Capture agent (for infrastructure monitoring)

On each server you want to monitor (Linux/Windows/macOS/Raspberry Pi — anywhere Go runs):

```sh
# Download appropriate binary from https://github.com/bluewave-labs/capture/releases
wget https://github.com/bluewave-labs/capture/releases/download/vX.Y.Z/capture-linux-amd64
chmod +x capture-linux-amd64
./capture-linux-amd64 --port 59232 --api-key <api-key-from-checkmate>
```

Run as systemd service for persistence. In Checkmate UI: add Infrastructure monitor → enter server IP + Capture port + API key.

## First boot

1. Browse `https://status.example.com` → register first user (becomes admin)
2. **Immediately close registration** (Settings → Users) unless you want public sign-ups
3. Add monitors: HTTP / Ping / Port / Docker / SSL / Infrastructure / JSON-query
4. Add notification channels (Settings → Notifications)
5. Link monitors ↔ channels
6. Create status page (Settings → Status Pages) — choose from 4 themes

## Data & config layout

- MongoDB — monitors, incidents, users, notification config, history
- Redis — ephemeral (caching + pub/sub); can be wiped without data loss
- Capture agent data — pushed to Checkmate's Mongo; stored server-side

## Backup

```sh
# MongoDB dump (primary backup target)
docker compose exec -T mongodb mongodump --archive --gzip > checkmate-db-$(date +%F).archive.gz

# Restore
cat checkmate-db-YYYY-MM-DD.archive.gz | docker compose exec -T mongodb mongorestore --archive --gzip

# .env with secrets
cp .env checkmate-env-$(date +%F).bak
```

## Upgrade

1. Releases: <https://github.com/bluewave-labs/Checkmate/releases>. Active.
2. `docker compose pull` (all 4 images — server, client, mongo, redis) → `docker compose up -d`.
3. Mongo schema migrations run on server startup; back up first.
4. Update Capture agents: `capture --update` or redeploy newer binary (protocol is backward-compatible within minor versions).

## Gotchas

- **MongoDB is the backbone** — not Postgres, not MySQL. If your infra standard is Postgres, accept the Mongo add-on or pick a different tool.
- **Capture agent is optional** — you can use Checkmate for URL/HTTP-only monitoring without installing Capture. Only install it on servers you want hardware metrics for.
- **Capture agent has network access to Checkmate** — if Checkmate is self-hosted behind a firewall, you need to punch a hole for Capture → Checkmate. Consider Tailscale/WireGuard for agent traffic.
- **First-user-is-admin race** — register first, close public registration. Don't expose publicly without this.
- **JWT_SECRET loss** = all users get logged out. Back up.
- **SMTP config** — `SYSTEM_EMAIL_TLS_SERVICE_PROVIDER: gmail` (or similar) is a Checkmate-specific shortcut for common providers. For custom SMTP, use explicit host/port/user/pass.
- **Notification channel testing** — use the "Test" button after configuring each channel. Silent failures (bad webhook URL, wrong Discord channel) = missed alerts.
- **Status page themes** are 4-pick; custom CSS isn't a first-class feature yet.
- **Incident timeline** is auto — every state change creates an incident; accumulates fast for flappy services. Tune `status change threshold` on the monitor to avoid noise.
- **Game server monitoring** supports common games (Minecraft, Valve, etc.); niche games may need JSON-query adapted for their query protocol.
- **Multi-tenancy**: Checkmate has users + roles but doesn't do "teams with separate dashboards" in the same way as SaaS competitors. Single-org design.
- **API** is emerging — check docs for the latest endpoints. Not as rich as commercial tools' APIs yet.
- **Mobile apps** — community-maintained; none official at the moment.
- **Custom CA support** documented at `docs/custom-ca-trust.md` — for monitoring internal HTTPS with private PKI (Smallstep etc.).
- **AGPL-3.0 license** — SaaS hosting triggers source-disclosure obligation.
- **Alternatives worth knowing:**
  - **Uptime Kuma** — very popular; web-UI; SQLite; less dev-oriented (separate recipe)
  - **Gatus** — config-as-code; rich condition DSL; stateless-capable (separate recipe)
  - **Healthchecks** — cron-job "dead-man's switch"; different use-case (pair with Checkmate for coverage) (separate recipe)
  - **Zabbix / Nagios / Icinga** — traditional enterprise infra monitoring; heavier; deeper
  - **Prometheus + Grafana + Alertmanager + node_exporter** — the gold-standard OSS stack; more setup
  - **Netdata** — real-time per-server dashboards; complements Checkmate
  - **UptimeRobot / Better Uptime / Pingdom** — commercial SaaS
  - **Choose Checkmate if:** you want uptime + infrastructure monitoring in one tool + OK with Node.js/MongoDB stack.
  - **Choose Uptime Kuma if:** you want simpler setup, web-UI-first, SQLite.
  - **Choose Gatus if:** you want config-as-code, rich assertions, minimal storage.
  - **Pair Checkmate with Healthchecks** for complete coverage.

## Links

- Repo: <https://github.com/bluewave-labs/checkmate>
- Capture agent: <https://github.com/bluewave-labs/capture>
- Website: <https://checkmate.so>
- Docs: <https://checkmate.so/docs>
- Custom CA trust guide: <https://github.com/bluewave-labs/Checkmate/blob/main/docs/custom-ca-trust.md>
- Helm chart: <https://github.com/bluewave-labs/Checkmate/tree/main/charts/helm/checkmate>
- Demo: <https://demo.checkmate.so>
- Discord: <https://discord.gg/NAb6H3UTjK>
- GitHub Discussions: <https://github.com/bluewave-labs/Checkmate/discussions>
- Releases: <https://github.com/bluewave-labs/Checkmate/releases>
- PikaPods: <https://www.pikapods.com/pods?run=checkmate>
- Coolify guide: <https://coolify.io/>
- Elestio: <https://elest.io/open-source/checkmate>
- BlueWave Labs: <https://bluewavelabs.ca>
