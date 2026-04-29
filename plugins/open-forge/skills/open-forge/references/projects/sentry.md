---
name: sentry-project
description: Sentry self-hosted recipe for open-forge. Functional Source License (FSL) error tracking + APM / tracing / profiling / session replay / uptime monitoring — packaged as the `getsentry/self-hosted` Docker Compose stack. Upstream explicitly positions self-hosted as "for low-volume deployments and proofs-of-concept," NOT feature parity with sentry.io SaaS. Stack is 50+ containers including Postgres, Redis, Kafka, ClickHouse, Snuba, Symbolicator, Relay, Vroom, Taskbroker, Snuba consumers. Canonical install is `git clone` + `./install.sh`; upgrades use the same script with a new tag. Resource floor is 4 CPU + 14 GB RAM (or 2 CPU + 7 GB RAM in `errors-only` profile). Covers install, upgrade, the errors-only profile, and the many footguns (clock drift breaks Kafka, disk fills up fast, no high-availability story).
---

# Sentry (self-hosted)

Functional Source License (FSL-1.1-Apache-2.0) error tracking + performance monitoring. Upstream repo: <https://github.com/getsentry/self-hosted>. Docs: <https://develop.sentry.dev/self-hosted/>. Main product: <https://sentry.io>.

Upstream's own tagline for self-hosted: *"feature-complete and packaged up for **low-volume deployments and proofs-of-concept**."* Read that carefully — self-hosted Sentry is not a drop-in for sentry.io SaaS at scale. For small teams (single-digit events/sec) it's fine; for real production traffic, upstream recommends SaaS or Sentry's paid dedicated hosting.

## License note

Sentry is **FSL** (Functional Source License) since late 2023 — source-available, NOT OSI-open-source. Key terms:

- You may use, modify, self-host for internal or non-competing purposes.
- You may NOT offer a "competing product" (i.e. build a hosted Sentry-as-a-service and resell it).
- After 2 years each release auto-converts to Apache 2.0.

If you self-host Sentry for your own company / project / club, you're fine. If you want to start a Sentry-reselling business, read the license carefully.

## What you're deploying

The self-hosted stack is ~50 containers:

| Category | Services |
|---|---|
| **App tier** | `web`, `worker`, `cron`, `post-process-forwarder-*`, `uptime-checker`, `taskworker`, `taskscheduler`, `taskbroker` |
| **Event ingestion** | `relay`, `ingest-*` (events, profiles, replay-recordings, monitors, feedback, occurrences), various `*-consumer`s |
| **Query engine** | `snuba-api`, `snuba-*-consumer` (errors, transactions, metrics, profiles, replays, spans, eap-items, outcomes, subscriptions, replacer, issue-occurrence, group-attributes) |
| **Storage** | `postgres`, `pgbouncer`, `redis`, `memcached`, `clickhouse`, `kafka`, `seaweedfs` (+ admin + worker) |
| **Native debugging** | `symbolicator` (+ `symbolicator-cleanup`), `vroom` (profiling) |
| **Infra** | `nginx` (edge router), `smtp`, `geoip` |
| **Cleanup** | `sentry-cleanup`, `symbolicator-cleanup` (nightly retention jobs) |

Public port: nginx on `:9000` (configurable). Reverse-proxy to it for TLS.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `getsentry/self-hosted` + `./install.sh` | <https://github.com/getsentry/self-hosted> | ✅ **The only supported method** | Canonical path. `git clone` + run installer. |
| Kubernetes Helm chart | <https://github.com/sentry-kubernetes/charts> | ⚠️ Community-maintained | Not officially supported by Sentry the company. Drifts. |
| Sentry Cloud (SaaS) | <https://sentry.io> | ✅ | What they want most people to use. Free tier + paid plans. |
| Single Tenant (SaaS dedicated) | Upstream sales | ✅ | Paid dedicated-instance offering. |

## Hardware requirements

From `install/_min-requirements.sh`:

| Profile | Min CPU | Min RAM |
|---|---|---|
| Default (all features) | 4 cores | 14 GB RAM |
| `COMPOSE_PROFILES=errors-only` | 2 cores | 7 GB RAM |

These are enforced — `install.sh` refuses to proceed on under-spec hosts. Also required:

- Docker ≥ 19.03.6
- Docker Compose ≥ 2.32.2 (or Podman ≥ 4.9.3 + podman-compose ≥ 1.3.0)
- Bash ≥ 4.4.0
- **SSE 4.2 CPU** — ClickHouse requires it. KVM-virtualized cpuinfo may hide SSE4.2; set `SKIP_SSE42_REQUIREMENTS=1` to override.
- ≥ 20 GB free disk (event data fills up fast; plan for more)
- **x86_64 or arm64 only**. arm64 works but may need `DOCKER_PLATFORM` overrides.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Sentry version? (git tag)" | Free-text, e.g. `25.4.0`; check <https://github.com/getsentry/self-hosted/releases> for current | Installer is version-locked to the git branch/tag checked out. |
| preflight | "Enable errors-only profile?" | Boolean | Sets `COMPOSE_PROFILES=errors-only`; drops APM/profiling/replay → halves resource floor. |
| install-dir | "Install directory?" | Free-text, default `/opt/sentry-self-hosted` | Clone target. |
| domain | "Public URL?" | Free-text, e.g. `https://sentry.example.com` | Set as `system.url-prefix` in `sentry/config.yml` on first boot. |
| tls | "Reverse proxy for HTTPS?" | `AskUserQuestion` | Upstream bundled nginx does NOT do TLS — terminate at Caddy/nginx/Traefik in front. |
| admin | "First admin email + password?" | Free-text (sensitive) | Created non-interactively during install, OR via `docker compose run --rm web createuser` after. |
| smtp | "SMTP host/port/user/pass?" | Free-text | Edit `sentry/config.yml`. Bundled `smtp` is for dev only. |
| retention | "Event retention days?" | Number, default 90 | `SENTRY_EVENT_RETENTION_DAYS` env var. |
| disk | "Data volumes path?" | Free-text, default Docker-managed volumes | Consider binding to a dedicated disk — ClickHouse + Kafka grow fast. |

## Install — `install.sh`

```bash
# 1. Clone a specific tag (pick one from releases page)
cd /opt
sudo git clone https://github.com/getsentry/self-hosted.git sentry-self-hosted
cd sentry-self-hosted
sudo git checkout 25.4.0   # pin to a release tag

# 2. (Optional) slim-down profile for error-tracking only
# export COMPOSE_PROFILES=errors-only

# 3. Run the installer
sudo ./install.sh
# The installer:
#  - Checks min requirements (CPU, RAM, Docker, Bash, SSE4.2)
#  - Pulls + builds Docker images (~20+ GB disk during build; SENTRY_IMAGE uses a local tag)
#  - Creates docker volumes
#  - Copies example config files into ./sentry/, ./relay/, ./snuba/
#  - Generates secret keys
#  - Bootstraps Snuba + Postgres schemas
#  - Runs migrations
#  - Prompts for first admin user email + password (interactive)

# 4. Bring the stack up
sudo docker compose up -d

# 5. Sanity check
sudo docker compose ps
# All services should be healthy; nginx listens on :9000
curl -I http://localhost:9000
```

Visit `http://<host>:9000` and log in with the admin creds you entered.

### Skip interactive prompts

```bash
sudo ./install.sh \
  --skip-user-prompt \
  --no-user-prompt   # create user later with docker compose run --rm web createuser

# or pass admin creds via flags (see `./install.sh --help`)
```

### errors-only profile

Disables the heavier APM/tracing/replay/profiling pipelines:

```bash
export COMPOSE_PROFILES=errors-only
sudo ./install.sh
sudo docker compose up -d
```

Drops min requirements to 2 CPU / 7 GB RAM. You keep error tracking, issues, alerts, and SDK compatibility — you lose performance monitoring dashboards, session replay UI, profiling, and uptime monitoring.

## Reverse proxy

```caddy
sentry.example.com {
    reverse_proxy 127.0.0.1:9000
    request_body {
        max_size 150MB  # minidump / source-map uploads
    }
}
```

For nginx, ensure `client_max_body_size 150M;` and disable buffering for SSE (Sentry uses SSE for real-time issue-detail updates):

```nginx
location / {
    proxy_pass http://127.0.0.1:9000;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 150M;
    proxy_read_timeout 300s;
}
```

Set `system.url-prefix: 'https://sentry.example.com'` in `sentry/config.yml` so outbound links (emails, webhooks) use HTTPS.

## Data layout

Docker volumes (see `docker-compose.yml`'s `volumes:` block):

| Volume | Content | Growth profile |
|---|---|---|
| `sentry-clickhouse` | ClickHouse data — events, transactions, spans, metrics | **Fastest grower.** Plan for 100s of GB on any real traffic. |
| `sentry-kafka-log` | Kafka topic segments (event buffer) | Grows until topic retention kicks in. Default retention ~3 days. |
| `sentry-postgres` | Postgres — orgs, projects, users, issue metadata | Slower grower; issue metadata only. |
| `sentry-redis` | Redis — cache + rate-limit state | Small (GBs). |
| `sentry-data` | SeaweedFS — attachments, minidumps, replays | Grows with attachment volume. |
| `sentry-symbolicator` | Symbol cache for native stacktraces | Cache; safe to prune. |
| `sentry-vroom-profiles` | Profiling blobs | APM-only. |
| `sentry-config` / `sentry-relay` / `sentry-snuba` | Config dirs | Small. |

**Disk is the #1 self-hosted Sentry pain point.** Monitor ClickHouse and SeaweedFS volume usage obsessively. Set `SENTRY_EVENT_RETENTION_DAYS` to something sane for your disk budget.

### Backups

```bash
# Postgres (metadata)
docker compose exec -T postgres pg_dumpall -U postgres > pg-$(date +%F).sql

# ClickHouse (events) — use clickhouse-backup or clickhouse-client
docker compose exec clickhouse clickhouse-client --query "BACKUP DATABASE default TO File('/var/lib/clickhouse/backups/sentry-$(date +%F).zip')"

# Stop + tar entire volume set (downtime-tolerant approach)
docker compose down
sudo tar czf sentry-volumes-$(date +%F).tar.gz /var/lib/docker/volumes/sentry-*
docker compose up -d
```

Full backup/restore playbook: <https://develop.sentry.dev/self-hosted/backup/>.

## Upgrade procedure

```bash
cd /opt/sentry-self-hosted

# 1. READ RELEASE NOTES FIRST
# https://github.com/getsentry/self-hosted/releases
# Some versions require manual DB migrations or ClickHouse schema changes.

# 2. Stop stack
sudo docker compose down

# 3. Pull new tag
sudo git fetch --tags
sudo git checkout 25.5.0   # new tag

# 4. Back up everything (see backup section)

# 5. Re-run installer — same script handles upgrades
sudo ./install.sh
# It runs upgrade-clickhouse.sh, upgrade-postgres.sh, and re-migrates the DB

# 6. Start
sudo docker compose up -d
sudo docker compose logs -f web
```

**No cross-major-version skips.** Upgrade one version at a time. Upstream publishes releases monthly.

### Downgrade

Not supported. Database migrations are one-way. If you upgrade and break things, restore from backup.

## Configuration

Two files land in `./sentry/` after install:

| File | Purpose |
|---|---|
| `sentry/config.yml` | YAML — `system.url-prefix`, `mail.*`, `filestore.backend`, etc. |
| `sentry/sentry.conf.py` | Python — Django settings, feature flags, auth providers. |

Common tweaks:

```yaml
# sentry/config.yml
system.url-prefix: 'https://sentry.example.com'
system.secret-key: '<generated>'   # DO NOT share
mail.host: 'smtp.example.com'
mail.port: 587
mail.username: 'sentry@example.com'
mail.password: '<smtp-pass>'
mail.use-tls: true
mail.from: 'sentry@example.com'
filestore.backend: 'filesystem'    # default; or 's3' for object storage
```

```python
# sentry/sentry.conf.py (selected)
SENTRY_OPTIONS["system.event-retention-days"] = int(env("SENTRY_EVENT_RETENTION_DAYS", "90"))
# Enable social auth, SSO, SAML, etc. via Django middleware settings here.
```

After editing:

```bash
sudo docker compose restart web worker cron
```

## Gotchas

- **"Low-volume deployments and proofs-of-concept"** is upstream's own language. At any real volume (100s of events/sec sustained) self-hosted Sentry's ClickHouse, Kafka, and Snuba will need tuning you won't get support for. Move to SaaS or plan for serious ops work.
- **Disk fills up fast.** ClickHouse + Kafka grow rapidly. Default retention is 90 days but defaults aren't enforced at the filesystem level — you need retention policies on ClickHouse tables too. Watch `df -h` daily.
- **Clock drift breaks Kafka.** Kafka's log segment rotation + consumer offsets assume monotonic clocks. Hosts without NTP/chrony running will corrupt topics over time. Enable systemd-timesyncd or chrony.
- **SSE4.2 requirement** comes from ClickHouse. Older/weird CPUs (or aggressive KVM masking) fail the installer. `SKIP_SSE42_REQUIREMENTS=1` is a hack that compromises ClickHouse reliability.
- **`install.sh` builds images locally** (`sentry-self-hosted-local`). A network hiccup during `docker compose build` can leave you with half-built images. Re-run; it's idempotent-ish.
- **SMTP is `smtp` container** (maildev-style catcher) by default. Password resets and invites go into the container's mail dir, NOT to real users. Configure real SMTP in `sentry/config.yml` before inviting humans.
- **`system.url-prefix`** must match your reverse-proxy's public URL exactly. Otherwise email links are broken and SSO redirects fail.
- **No built-in HA.** Postgres is single-node, Kafka is single-broker, ClickHouse is single-shard in the bundled compose. For HA you need custom orchestration or Sentry's paid Single Tenant.
- **arm64 may require `DOCKER_PLATFORM` overrides.** Some images don't have arm64 builds. The compose file defaults to `${DOCKER_PLATFORM:-}` — set explicitly if Apple Silicon: `export DOCKER_PLATFORM=linux/arm64/v8`.
- **Upgrades require `./install.sh`, NOT just `docker compose pull`.** The installer runs DB migrations + ClickHouse schema upgrades + cert regeneration. Pulling images manually and restarting will break things.
- **Downgrades impossible.** Plan rollback via backup restore, not version downgrade.
- **Helm charts are NOT supported by Sentry.** Community-maintained at <https://github.com/sentry-kubernetes/charts>. Drift from upstream is common; features sometimes arrive months late. If you need K8s production Sentry, consider SaaS.
- **Uptime monitoring + crons + replay + profiling** are ALL opt-out by default in errors-only. If you install default then switch to errors-only later, orphan data sticks around in volumes.
- **FSL license terms.** Internal company use is fine. Do NOT resell as a hosted Sentry competitor.
- **First admin user bootstrap is critical.** If you skip it (`--no-user-prompt`), the sign-up flow on fresh install lets anyone create the first admin — firewall port 9000 until you've created the user with `docker compose run --rm web createuser`.

## Links

- Upstream repo: <https://github.com/getsentry/self-hosted>
- Self-hosted docs: <https://develop.sentry.dev/self-hosted/>
- Install guide: <https://develop.sentry.dev/self-hosted/installation/>
- Troubleshooting: <https://develop.sentry.dev/self-hosted/troubleshooting/>
- Backup guide: <https://develop.sentry.dev/self-hosted/backup/>
- Releases: <https://github.com/getsentry/self-hosted/releases>
- Sentry SaaS: <https://sentry.io>
- License (FSL-1.1-Apache-2.0): <https://github.com/getsentry/self-hosted/blob/master/LICENSE.md>
- Community Helm charts (NOT official): <https://github.com/sentry-kubernetes/charts>
- Dev-facing SDK docs: <https://docs.sentry.io>
