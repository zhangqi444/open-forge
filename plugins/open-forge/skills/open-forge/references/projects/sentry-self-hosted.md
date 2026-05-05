# Sentry (Self-Hosted)

Sentry is an open-source application monitoring platform for error tracking, performance monitoring, session replay, and profiling. The self-hosted distribution (`getsentry/self-hosted`) packages the full Sentry stack for low-volume on-premise deployments.

**Official site:** https://sentry.io  
**GitHub:** https://github.com/getsentry/self-hosted  
**Upstream README:** https://github.com/getsentry/self-hosted/blob/master/README.md  
**Docs:** https://develop.sentry.dev/self-hosted/  
**License:** BUSL 1.1 (Sentry SDKs are Apache 2.0; server source under BUSL)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VM / VPS (≥4 vCPU, 8 GB RAM) | Docker Compose | Official and recommended method |
| Kubernetes | Community Helm chart (`sentry-kubernetes/charts`) | Not officially supported |

> **Minimum:** 4 CPU cores, 8 GB RAM, 20 GB disk. Recommended for production: 8+ cores, 16+ GB RAM.

---

## Inputs to Collect

### Before installation
- Domain / hostname (for `SENTRY_SYSTEM_URL_PREFIX`)
- SMTP credentials (for email notifications and invites)
- `SENTRY_EVENT_RETENTION_DAYS` — how long events are retained (default: 90)
- Admin email + password (set interactively during `install.sh`)
- TLS: handled by a reverse proxy (nginx/Caddy/Traefik) in front of Sentry

### Optional
- SSO / OAuth provider config (GitHub, Google, SAML)
- File storage backend (default: local disk; can switch to S3/GCS via env)
- Slack / PagerDuty integration tokens

---

## Software-Layer Concerns

### Installation method
Sentry self-hosted uses a shell installer, not a plain `docker compose up`:
```bash
git clone https://github.com/getsentry/self-hosted.git
cd self-hosted
# Optionally pin a release tag: git checkout 24.x.x
./install.sh
```
The installer:
1. Checks system requirements
2. Generates `sentry/config.yml` and `.env`
3. Pulls all images and runs DB migrations
4. Prompts to create an admin user

### Starting / stopping
```bash
docker compose up -d          # start
docker compose down           # stop
docker compose run --rm sentry upgrade   # run migrations after update
```

### Key configuration files
- `.env` — environment overrides (event retention, secret key, etc.)
- `sentry/config.yml` — main Sentry Python/Django config
- `sentry/sentry.conf.py` — advanced Python overrides

### Ports
| Port | Purpose |
|------|---------|
| 9000 | Sentry web UI (HTTP) — proxy this with nginx/Caddy |

### Data volumes
- PostgreSQL data, Redis data, Kafka logs, uploaded attachments — all managed via named Docker volumes
- Backup: `docker compose run --rm -T -e SENTRY_LOG_LEVEL=CRITICAL web export` (exports JSON)

### Services started
Sentry self-hosted runs ~20 containers (web, worker, cron, snuba, kafka, zookeeper, redis, postgres, clickhouse, etc.)

---

## Upgrade Procedure

```bash
cd self-hosted
git fetch
git checkout <new-version-tag>
./install.sh      # re-runs migrations and pulls new images
docker compose up -d
```

> Always pin to a release tag rather than `master` for production. Check the [CHANGELOG](https://github.com/getsentry/self-hosted/blob/master/CHANGELOG.md) for breaking changes between releases.

---

## Gotchas

- **Resource hungry** — Sentry self-hosted is not lightweight; it won't run well on a 2 GB VPS
- **Kafka + ClickHouse** — the stack includes Kafka and ClickHouse, which significantly raise memory requirements
- **`./install.sh` must be re-run on upgrade** — do not just `git pull && docker compose up -d`; the installer handles migrations
- **Email required** — without SMTP, user invites and alerts won't work; set up SMTP in `.env` before creating users
- **Clock skew** — Sentry is sensitive to system time; ensure the host clock is synced (NTP)
- **Retention tuning** — reduce `SENTRY_EVENT_RETENTION_DAYS` on smaller disks; events + attachments accumulate fast
- **Backup** — named Docker volumes contain all data; back up with `docker run --rm -v <volume>:/data alpine tar czf - /data`

---

## Links

- Self-hosted docs: https://develop.sentry.dev/self-hosted/
- Configuration reference: https://develop.sentry.dev/self-hosted/configuration/
- Upgrading: https://develop.sentry.dev/self-hosted/releases/
- Community Helm chart: https://github.com/sentry-kubernetes/charts
