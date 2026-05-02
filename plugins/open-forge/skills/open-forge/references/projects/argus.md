# Argus

**What it is:** Release monitoring and notification service. Watches GitHub repos, Docker registries, and arbitrary URLs for new software releases, then triggers notifications (Gotify, Slack, and others) and/or webhooks when a new version is detected.

**Official site:** https://release-argus.io  
**Demo:** https://release-argus.io/demo  
**Docs:** https://release-argus.io/docs/  
**GitHub:** https://github.com/release-argus/Argus  
**Docker Hub:** `releaseargus/argus`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container, config via YAML |
| Any Linux VPS/VM | Binary | Single static binary, no dependencies |
| Bare metal | Binary | Same as above |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Config file path | Path to `config.yml` — mounted into container |
| Listen port | Default `8080` |
| Data/database path | Default `data/argus.db` (SQLite) |

### Phase: Config (`config.yml`)

Config is broken into 5 sections:

| Section | Purpose |
|---------|---------|
| `defaults` | Default settings for services, notify targets, webhooks |
| `settings` | Server settings (listen host/port, basic auth, TLS) |
| `service` | Dictionary of services to monitor and their notify/webhook triggers |
| `notify` | Dictionary of notification targets (Gotify, Slack, etc.) |
| `webhook` | Dictionary of webhook targets |

---

## Software-Layer Concerns

- **Single SQLite database** at `data/argus.db` — persist this volume
- **Config file** is the source of truth; reload by restarting the container/binary
- **Basic auth** can be set via CLI flags or env vars (`ARGUS_WEB_BASIC_AUTH_USERNAME` / `ARGUS_WEB_BASIC_AUTH_PASSWORD`)
- **TLS** supported via `--web.cert-file` and `--web.pkey-file` (or behind a reverse proxy)
- **Log level** configurable: `ERROR`, `WARN`, `INFO`, `VERBOSE`, or `DEBUG`

### Key environment variables

| Env Var | Description |
|---------|-------------|
| `ARGUS_CONFIG_FILE` | Path to config file (default `config.yml`) |
| `ARGUS_DATA_DATABASE_FILE` | SQLite DB path (default `data/argus.db`) |
| `ARGUS_WEB_LISTEN_PORT` | Listen port (default `8080`) |
| `ARGUS_WEB_LISTEN_HOST` | Listen host (default `0.0.0.0`) |
| `ARGUS_WEB_BASIC_AUTH_USERNAME` | Basic auth username |
| `ARGUS_WEB_BASIC_AUTH_PASSWORD` | Basic auth password |
| `ARGUS_LOG_LEVEL` | Log verbosity |

---

## Example Docker Compose

```yaml
services:
  argus:
    image: releaseargus/argus
    container_name: argus
    ports:
      - "8080:8080"
    volumes:
      - ./config.yml:/app/config.yml
      - argus_data:/app/data
    environment:
      ARGUS_CONFIG_FILE: /app/config.yml
    restart: unless-stopped

volumes:
  argus_data:
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. For binary: download new release from GitHub releases page, replace binary, restart service

---

## Gotchas

- Config file changes require a restart — there is no hot-reload
- GitHub API rate limits apply when monitoring many GitHub repos without authentication; set a GitHub token in service config to raise limits
- `--web.route-prefix` is useful when hosting behind a reverse proxy at a sub-path
- The `--config.check` flag prints the fully-parsed config — useful for debugging YAML issues
- No multi-user support; basic auth is a single username/password pair

---

## Links

- Website: https://release-argus.io
- Docs: https://release-argus.io/docs/getting-started/
- GitHub: https://github.com/release-argus/Argus
- Docker Hub: https://hub.docker.com/r/releaseargus/argus
