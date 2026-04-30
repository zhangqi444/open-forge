---
name: LibreSpeed
description: No-Flash / no-Java / no-WebSocket HTML5 speed-test. Self-host your own speedtest.net. Also supports multi-POP mode with multiple backend servers. LGPL-3.0.
---

# LibreSpeed

LibreSpeed is a self-hosted alternative to speedtest.net / fast.com — pure HTML5 + JS (no Flash, Java, or WebSockets), lightweight enough to run on a Raspberry Pi, and privacy-friendly (no telemetry sent to a third party unless you opt in).

Use cases: ISP diagnostics, VPN throughput verification, internal LAN speed-testing, local-first alternatives to commercial speedtest services.

- Upstream repo: <https://github.com/librespeed/speedtest>
- Docker docs: <https://github.com/librespeed/speedtest/blob/master/doc_docker.md>
- Public demo: <https://librespeed.org>
- Image: `ghcr.io/librespeed/speedtest`

## Architecture in one minute

One container, one PHP frontend + backend on nginx. Three operating modes:

1. **`MODE=standalone`** — backend + frontend in one container (default). Classic self-host.
2. **`MODE=backend`** — only the measurement endpoints (`garbage.php`, `empty.php`, `getIP.php`). Use across multiple POPs.
3. **`MODE=frontend`** — only the client-side + server-list JSON. Points at multiple backends.

Telemetry (result history) is optional. Supports SQLite (default, file-based), MySQL, PostgreSQL.

## Compatible install methods

| Infra        | Runtime                                            | Notes                                                                   |
| ------------ | -------------------------------------------------- | ----------------------------------------------------------------------- |
| Single VM    | Docker (`ghcr.io/librespeed/speedtest`)            | **Recommended.** Multi-arch                                              |
| Single VM    | Docker (`*-alpine` variant)                        | Smaller image; musl libc                                                |
| Bare metal   | PHP 7+ / nginx or Apache                           | `git clone` the repo into web root                                      |
| Raspberry Pi | Docker (armv7 / arm64)                             | Great low-cost always-on speedtest                                      |
| Kubernetes   | Plain Deployment + Service                         | Stateless unless telemetry is enabled                                   |
| Go backend   | `go-backend` subdir for a single-binary deployment | Alternative backend if PHP is unwelcome                                 |

## Inputs to collect

| Input                       | Example                                 | Phase    | Notes                                                              |
| --------------------------- | --------------------------------------- | -------- | ------------------------------------------------------------------ |
| `MODE`                      | `standalone` (most common)              | Runtime  | Or `backend` / `frontend` for multi-POP                             |
| Port                        | `80:8080` (host:container)              | Network  | `WEBPORT` env changes the container-internal port                   |
| `TITLE` / `TAGLINE`         | "My ISP speed test" / "…"              | Runtime  | Branding                                                            |
| `TELEMETRY`                 | `true` / `false`                        | Runtime  | Persists results to DB                                              |
| `PASSWORD`                  | strong                                  | Runtime  | Required to view stats page (`/results/stats.php`)                  |
| `DB_TYPE`                   | `sqlite` (default) / `mysql` / `postgresql` | DB  | External DB via additional env vars                                 |
| `IPINFO_APIKEY`             | optional                                | Runtime  | Required for distance measurement (ipinfo.io key)                   |
| `REDACT_IP_ADDRESSES`       | `true` / `false`                        | Privacy  | Don't store client IPs in telemetry                                 |
| `ENABLE_ID_OBFUSCATION`     | `true` / `false`                        | Privacy  | Hide sequential test IDs in public result URLs                       |
| `GDPR_EMAIL`                | `privacy@example.com`                   | Privacy  | Contact for data-deletion requests (GDPR compliance)                 |
| `USE_NEW_DESIGN`            | `true` / `false`                        | UI       | Opt in to the newer modern frontend                                 |

## Install via Docker Compose (standalone)

From <https://github.com/librespeed/speedtest/blob/master/doc_docker.md>:

```yaml
services:
  speedtest:
    container_name: speedtest
    image: ghcr.io/librespeed/speedtest:latest
    restart: always
    environment:
      MODE: standalone
      TITLE: "My Speed Test"
      TELEMETRY: "false"          # flip to "true" + set PASSWORD to enable stats
      # PASSWORD: "stats-admin-password"
      # ENABLE_ID_OBFUSCATION: "true"
      # REDACT_IP_ADDRESSES: "true"
      # GDPR_EMAIL: "privacy@example.com"
      # USE_NEW_DESIGN: "true"
      # IPINFO_APIKEY: "<ipinfo.io token>"
      # DISTANCE: "km"
    ports:
      - "80:8080"
    # For persisted telemetry via SQLite:
    # volumes:
    #   - ./speedtest-db:/database
```

### Quick run

```sh
docker run -p 80:8080 -d --name speedtest --restart unless-stopped \
  ghcr.io/librespeed/speedtest
```

### With telemetry + stats page

```sh
docker run -d --name speedtest --restart unless-stopped \
  -p 86:86 \
  -e MODE=standalone \
  -e TELEMETRY=true \
  -e ENABLE_ID_OBFUSCATION=true \
  -e REDACT_IP_ADDRESSES=true \
  -e PASSWORD='strong-admin-password' \
  -e GDPR_EMAIL='privacy@example.com' \
  -e WEBPORT=86 \
  -v "$PWD/db-dir:/database" \
  ghcr.io/librespeed/speedtest
```

Stats page at `http://host:86/results/stats.php`; log in with `PASSWORD`.

### External MySQL/Postgres

```yaml
services:
  speedtest:
    image: ghcr.io/librespeed/speedtest:latest
    environment:
      MODE: standalone
      TELEMETRY: "true"
      PASSWORD: 'strong'
      DB_TYPE: mysql            # or postgresql
      DB_HOSTNAME: db
      DB_PORT: 3306             # mysql only
      DB_NAME: speedtest
      DB_USERNAME: speedtest
      DB_PASSWORD: strong
    ports:
      - "80:8080"
    depends_on: [db]

  db:
    image: mariadb:11
    environment:
      MARIADB_ROOT_PASSWORD: strong
      MARIADB_DATABASE: speedtest
      MARIADB_USER: speedtest
      MARIADB_PASSWORD: strong
    volumes:
      - ./mariadb-data:/var/lib/mysql
```

**Important:** with external DB, you must create the schema manually before first boot — see <https://github.com/librespeed/speedtest/blob/master/doc.md#creating-the-database> for the exact CREATE TABLE statements.

## Multi-POP (frontend + multiple backends)

For large-scale deployments where you want multiple geographic measurement points:

1. Deploy many `MODE=backend` containers across regions.
2. Deploy one `MODE=frontend` container (or edit `servers.json` on any standalone).
3. Point frontend at the backend list via `SERVER_LIST_URL` or bind-mount a custom `servers.json`.

Frontend then picks the closest backend based on ICMP-like ping from browser.

## Data & config layout

Inside the container:

- `/database/db.sql` — SQLite telemetry file (if `DB_TYPE=sqlite`; default)
- `/webroot/` — static HTML/JS/PHP
- `/webroot/servers.json` — list of backends for multi-POP (can override via `SERVER_LIST_URL`)
- `/webroot/results/stats.php` — stats + leaderboard page (password-gated)

No persistent state needed unless telemetry is on. Mount `/database` to preserve SQLite across image updates.

## Backup

```sh
# SQLite telemetry
cp ./db-dir/db.sql speedtest-db-$(date +%F).sql

# External DB — usual pg_dump / mariadb-dump
docker compose exec -T db mariadb-dump -uroot -p<pw> speedtest | gzip > speedtest-$(date +%F).sql.gz
```

LibreSpeed is mostly stateless; backup matters only if you care about long-term result history.

## Upgrade

1. Releases: <https://github.com/librespeed/speedtest/releases>.
2. Docker: `docker compose pull && docker compose up -d`.
3. Schema changes are rare but possible — read release notes for breaking changes before bumping across majors.
4. Bare-metal: `git pull` the repo; client-side JS + PHP are drop-in.

## Gotchas

- **Telemetry off by default.** `TELEMETRY=false` means no results are saved. Flip `TELEMETRY=true` + set `PASSWORD` to enable the stats page.
- **Stats page has NO access control without `PASSWORD`.** Never enable telemetry without also setting `PASSWORD`, or your results page is fully public (including client IPs unless redacted).
- **Measurement accuracy depends on the link between YOUR host and the CLIENT.** If your LibreSpeed is on a 100 Mbps VPS, you can't measure gigabit connections — the server is the bottleneck. Host on adequate bandwidth.
- **IPv6 measurements require IPv6 on the server.** Dual-stack hosts show two result columns; IPv4-only hosts silently skip v6 tests.
- **ipinfo.io integration is rate-limited.** Without an API key, ISP + distance info uses their free tier (50k req/mo public). Set `DISABLE_IPINFO=true` for strict privacy or to avoid the rate limit. Set `IPINFO_APIKEY` for paid tiers.
- **ISP/distance is "best effort".** The offline ipinfo DB baked into the image is 30+ days old by release time; commercial data shifts. Don't bet legal decisions on this data.
- **GDPR_EMAIL is a regulatory requirement, not cosmetics.** Running a public speedtest that stores IPs without a published contact for deletion requests violates GDPR in the EU. Set it (or enable `REDACT_IP_ADDRESSES=true`).
- **New vs. old UI.** Default is the classic UI. `USE_NEW_DESIGN=true` opts into the modern design. Or users can flip via URL: `?design=new` / `?design=old`.
- **`OBFUSCATION_SALT` auto-generates if not set.** This means obfuscated IDs change on every container restart → old shareable result URLs break. Set a static salt (`OBFUSCATION_SALT=0x...`) to keep IDs stable.
- **WEBPORT env changes INTERNAL port only.** You still need `-p HOST:WEBPORT` to expose it. Common confusion: people set `WEBPORT=86` and forget to map `-p 86:86`.
- **No websockets, no HTTP/2 streaming.** The test uses plain HTTP/1.1 GET + POST with long bodies. Behind an HTTP/2-only proxy with short timeouts, large tests can be cut off.
- **Buffer bloat is not measured.** Classic speed-down + speed-up only; for bufferbloat/jitter analysis, look at alternative tools (Waveform Bufferbloat, dslreports).
- **`PHP_MAX_*` limits** may need tuning for long tests. Upstream image sets reasonable defaults; custom PHP builds may need `max_execution_time` bumped.
- **SSL-offload best practice.** Terminate TLS at Caddy/Traefik/nginx; LibreSpeed container serves plain HTTP internally. HTTPS is required for accurate results on public sites (browsers block mixed content).
- **Alternatives worth knowing:**
  - **OpenSpeedTest** — another self-hostable speedtest, WebRTC-based, single-page
  - **iperf3** — CLI tool for more accurate lab testing
  - **speedtest-cli** — Ookla's CLI, uses Ookla's public servers

## Links

- Repo: <https://github.com/librespeed/speedtest>
- Docker docs: <https://github.com/librespeed/speedtest/blob/master/doc_docker.md>
- Main docs: <https://github.com/librespeed/speedtest/blob/master/doc.md>
- Go backend: <https://github.com/librespeed/speedtest-go>
- Releases: <https://github.com/librespeed/speedtest/releases>
- Container: <https://github.com/librespeed/speedtest/pkgs/container/speedtest>
- Demo: <https://librespeed.org>
- Multi-POP mode: <https://github.com/librespeed/speedtest/blob/master/doc_docker.md#multiple-points-of-test>
- Alternative: OpenSpeedTest — <https://github.com/openspeedtest/Speed-Test>
