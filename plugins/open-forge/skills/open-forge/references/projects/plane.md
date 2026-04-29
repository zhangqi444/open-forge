---
name: plane-project
description: Plane recipe for open-forge. AGPL-3.0 (Community) / commercial (Pro/Business) open-source project management tool (issues, cycles, modules, views, pages, analytics). Python/Django API + Next.js frontend, Postgres + Redis + MinIO, packaged as a multi-container Docker Compose stack. Covers the two upstream-blessed install paths — Commercial-edition one-liner (`prime.plane.so/install`) and Community-edition `setup.sh`-driven Docker Compose — plus a pointer to the community Kubernetes Helm chart.
---

# Plane

Open-source project management tool — issues, cycles, modules, views, pages, analytics, Git-style project layout. Upstream: <https://github.com/makeplane/plane>. Developer docs: <https://developers.plane.so/self-hosting/overview>. User docs: <https://docs.plane.so/>.

Plane ships as two editions:

- **Community Edition** — AGPL-3.0. Core issue tracker + cycles + modules + views + pages. Self-host is fully free.
- **Commercial Edition (Pro / Business)** — closed-source add-ons on top of Community. The "Free plan on the Commercial edition" unlocks a trial of paid features; activating a license key unlocks full Pro/Business.

Both editions self-host identically via Docker Compose; what differs is the image tag and the license-activation step.

## Architecture (what the compose stack runs)

- **web** — Next.js (user app, port 3000 → fronted by nginx at `:80`/`:443`)
- **admin** — Next.js (instance admin / "God Mode")
- **space** — Next.js (public project views / "deploy" surface)
- **live** — WebSocket server for realtime
- **api** — Python/Django REST API
- **worker** — Celery worker
- **beat-worker** — Celery beat scheduler
- **migrator** — one-shot DB migration container (runs then exits)
- **plane-db** — Postgres
- **plane-redis** — Redis
- **plane-minio** — S3-compatible object storage (swap for external S3/R2/GCS in production)
- **proxy** — nginx fronting all of the above

Default public entry point: `:80` (configurable via `LISTEN_HTTP_PORT`). TLS is done by the nginx in the stack OR by a separate reverse proxy in front.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose — Commercial edition one-liner | `curl -fsSL https://prime.plane.so/install/ \| sh -` | ✅ | Upstream's recommended path. Starts Commercial edition (free plan by default; upgrade with license key). |
| Docker Compose — Community edition (`setup.sh`) | <https://github.com/makeplane/plane/releases/latest/download/setup.sh> | ✅ | AGPL Community edition; manually-managed setup.sh downloads `docker-compose.yaml` + `plane.env`. |
| Kubernetes (Helm) | <https://developers.plane.so/self-hosting/methods/kubernetes> | ✅ | Upstream-documented K8s chart. |
| Source / `docker-compose.yml` in repo root | `makeplane/plane/docker-compose.yml` | ⚠️ Dev-only | The repo's `docker-compose.yml` + `setup.sh` are the DEVELOPMENT env setup. Not for production. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Edition? (Commercial-free / Community AGPL / Kubernetes)" | `AskUserQuestion` | Drives install path. |
| preflight | "Install dir?" | Free-text, default `/opt/plane-app` | `setup.sh` creates its own `plane-app/` subdir. |
| host | "Minimum 4GB RAM available? (8GB recommended for production)" | Boolean | Upstream's minimum; below this, migrator OOMs on first boot. |
| domain | "Public FQDN?" | Free-text (e.g. `plane.example.com`) | Written into `WEB_URL` + `CORS_ALLOWED_ORIGINS` in `plane.env`. |
| ports | "HTTP port? (default 80)" | Free-text | `LISTEN_HTTP_PORT` in `plane.env`. Change if already in use. |
| ports | "HTTPS port? (default 443)" | Free-text | `LISTEN_HTTPS_PORT`. |
| storage | "Use bundled MinIO, or external S3-compatible?" | `AskUserQuestion` | External recommended for production — survives Plane host loss. |
| db | "Use bundled Postgres, or external DB?" | `AskUserQuestion` | Same. External is recommended for production durability. |
| license | "Paste commercial license key (or leave blank for free plan)?" | Free-text (sensitive) | Activated from the admin UI after boot. |
| smtp | "SMTP for outbound email? (host / port / user / pass / from)" | Free-text | Sets `EMAIL_*` in `plane.env`. Required for invitations, password resets. |

## Install — Commercial edition one-liner

Per upstream docs (`developers.plane.so/self-hosting/methods/docker-compose`):

```bash
# SSH in as root or sudo-capable user
curl -fsSL https://prime.plane.so/install/ | sh -
```

The interactive flow prompts for:

1. **Domain name** (e.g. `plane.example.com` or `subdomain.domain.tld`).
2. **Install mode** — **Express** (default config, bundled Postgres/Redis/MinIO) or **Advanced** (customize DB / Redis / storage).

After install, visit the domain and create the first admin (first signup = instance admin). If you have a Pro / Business license key, activate it under **God Mode → Licenses**.

## Install — Community edition (setup.sh)

Per upstream's "Install Community Edition" block under the same docs page:

```bash
# 1. Prereqs: Docker + docker compose. Install via:
curl -fsSL https://get.docker.com | sh -

# 2. Create deploy dir
sudo mkdir -p /opt/plane-selfhost && cd /opt/plane-selfhost

# 3. Download the setup helper from the latest release
sudo curl -fsSL -o setup.sh \
  https://github.com/makeplane/plane/releases/latest/download/setup.sh
sudo chmod +x setup.sh

# 4. Run — it presents a numbered action menu
sudo ./setup.sh
# Menu:
#   1) Install (arm64) / (amd64) — autodetects
#   2) Start
#   3) Stop
#   4) Restart
#   5) Upgrade
#   6) View Logs
#   7) Backup Data
#   8) Exit
```

Choose **1) Install** first. This creates `plane-app/` (or `plane-app-preview/`) containing `docker-compose.yaml` + `plane.env`, and pulls images.

**Before `Start`, edit `plane-app/plane.env`:**

| Key | Default | Change to |
|---|---|---|
| `LISTEN_HTTP_PORT` | `80` | Your public HTTP port if 80 is taken. |
| `LISTEN_HTTPS_PORT` | `443` | Your public HTTPS port if 443 is taken. |
| `WEB_URL` | `http://localhost` | `https://plane.example.com` (or the IP + port). |
| `CORS_ALLOWED_ORIGINS` | `http://localhost` | Must match `WEB_URL` exactly. |
| `SECRET_KEY` | (generated) | Leave unless replacing for HA. Treat as sensitive. |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | Set | Change for production if using bundled DB. |
| `AWS_S3_*` / `USE_MINIO` | Bundled MinIO | For external S3, set `USE_MINIO=0` + fill `AWS_S3_ENDPOINT_URL` + creds. |
| `EMAIL_HOST` / `EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD` / `EMAIL_FROM` | Empty | Required for invites + password resets. |

Then `sudo ./setup.sh` → option `2) Start`. Wait for migrator to finish (first boot takes 2–5 min).

Visit `${WEB_URL}` and create the first admin account.

## Install — Kubernetes

Upstream publishes a Helm chart at <https://developers.plane.so/self-hosting/methods/kubernetes>. The values file mirrors `plane.env`; you'll supply:

- Ingress class + TLS secret
- External Postgres host / creds
- External Redis host
- S3-compatible storage creds

Not going to reproduce the chart values here — follow the upstream guide end-to-end. The operational model (migrator runs as a Job, Celery workers as Deployments) is the same as Compose.

## Reverse proxy in front of Plane

The stack's nginx (`proxy` service) terminates TLS via Let's Encrypt if `DOMAIN_NAME` + email are set. If you prefer your own reverse proxy (Caddy / Traefik / external nginx):

1. In `plane.env`, set `LISTEN_HTTP_PORT` to an unused port (e.g. `8080`), and don't use the stack's HTTPS.
2. Point your reverse proxy at `http://<plane-host>:8080`. Example Caddyfile:

```caddy
plane.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

## Upgrade procedure

### Commercial edition

```bash
curl -fsSL https://prime.plane.so/install/ | sh -
# Re-running the one-liner upgrades in place.
```

### Community edition

```bash
cd /opt/plane-selfhost
sudo ./setup.sh
# Choose option 5) Upgrade
# setup.sh pulls new images + runs migrator
```

**Back up before upgrading** (option `7) Backup Data`, or manually tar the named volumes + dump Postgres). Major-version bumps occasionally require downtime for long-running migrations.

## Backup

```bash
cd /opt/plane-selfhost
sudo ./setup.sh  # choose 7) Backup Data
```

The setup.sh backup dumps Postgres + archives the MinIO volume + copies plane.env. Output lands in `plane-app/backup/` or a path you specify.

Manual backup (more control):

```bash
# Postgres dump
docker exec plane-app-plane-db-1 pg_dump -U plane -d plane > plane-$(date +%F).sql

# MinIO volume
sudo tar -czf minio-$(date +%F).tar.gz \
  $(docker volume inspect plane-app_uploads -f '{{.Mountpoint}}')

# Config
sudo cp plane-app/plane.env plane.env.$(date +%F)
```

## Gotchas

- **Repo's `docker-compose.yml` is DEV-ONLY.** It builds images from local Dockerfiles — huge build times, no upgrade story. For production, use `setup.sh`'s downloaded compose (Community) or the prime.plane.so installer (Commercial).
- **`CORS_ALLOWED_ORIGINS` must exactly match `WEB_URL`.** Mismatch causes silent API 403s on the frontend (login works but nothing loads). Include the port if non-default.
- **`WEB_URL` changes require a full restart** — Celery workers cache it at boot. `setup.sh → 4) Restart` or `docker compose down && up -d`.
- **First admin = instance admin.** Whoever signs up first gets God Mode. On public-facing deploys, either firewall the domain during bootstrap or set `SIGNUP_ENABLED=0` right after you claim the account.
- **Bundled MinIO doesn't scale.** Fine for < 100 users. For real teams, switch to external S3 / R2 / GCS via `AWS_S3_*` env vars. Migration story is export-from-MinIO-then-import-to-S3; not one-click.
- **Commercial vs Community confusion.** The `prime.plane.so/install` installer defaults to Commercial (free plan). If you specifically want AGPL Community, you MUST use the `setup.sh` path — the installer does not offer Community as an option.
- **4GB RAM minimum, not recommendation.** Below 4GB, the migrator container runs out of memory during initial schema migrations and the stack never comes up clean. Cloud-provider small VPSes often don't meet this; check before deploying.
- **Redis is assumed reachable from workers AND web.** If you split services across hosts, every container that talks to `plane-redis` needs network reachability. `REDIS_URL` in `plane.env` can point externally.
- **Cycles + Modules + Views features can be disabled per-project.** Admins sometimes confuse "I disabled Cycles" for "Cycles are broken." Check project settings before filing bugs.
- **Backup script excludes Redis.** Redis holds Celery state, not user data — not backed up by `setup.sh → 7`. Acceptable.
- **Plane Pro upgrade path from Community** requires reinstalling via the Commercial one-liner and pointing it at your existing DB. There's no in-place `setup.sh`-to-prime.plane.so upgrade.

## Links

- Upstream repo: <https://github.com/makeplane/plane>
- Self-hosting overview: <https://developers.plane.so/self-hosting/overview>
- Docker Compose guide: <https://developers.plane.so/self-hosting/methods/docker-compose>
- Kubernetes guide: <https://developers.plane.so/self-hosting/methods/kubernetes>
- External DB / storage: <https://developers.plane.so/self-hosting/govern/database-and-storage>
- God Mode / instance admin: <https://developers.plane.so/self-hosting/govern/instance-admin>
- User docs: <https://docs.plane.so/>
- Releases: <https://github.com/makeplane/plane/releases>
- Forum: <https://forum.plane.so>
