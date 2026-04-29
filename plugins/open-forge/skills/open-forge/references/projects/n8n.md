---
name: n8n-project
description: n8n recipe for open-forge. Self-hosted workflow automation platform (Node.js). Covers Docker (official), Docker Compose with Postgres, npm/npx quick-start, and the key env vars (N8N_HOST, N8N_PROTOCOL, WEBHOOK_URL, DB_*, encryption key persistence).
---

# n8n (workflow automation)

n8n is a fair-code licensed workflow automation platform. 400+ integrations, native AI (LangChain-based), self-hostable. Default single-node install is SQLite in a Docker volume; production-ish self-host uses Postgres.

**Upstream README:** https://github.com/n8n-io/n8n/blob/master/README.md
**Upstream docs (self-hosting):** https://docs.n8n.io/hosting/
**Docker image:** `docker.n8n.io/n8nio/n8n` (official, published by n8n)

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker | ✅ default | README quick-start |
| localhost | native (npm/npx) | ✅ | `npx n8n` — ephemeral / dev only |
| byo-vps | Docker | ✅ | Add a reverse proxy (Caddy / Traefik / Nginx) for TLS |
| byo-vps | Docker Compose | ✅ | Recommended for Postgres + persistent volume |
| aws/ec2 | Docker Compose | ✅ | Expose 443 only; terminate TLS at Caddy or ALB |
| hetzner/cloud-cx | Docker Compose | ✅ | |
| digitalocean/droplet | Docker Compose | ✅ | DO has an official 1-click Droplet marketplace image — see upstream docs |
| gcp/compute-engine | Docker Compose | ✅ | |
| kubernetes | community Helm | ⚠️ | No official chart; community chart at `8gears/n8n-helm-chart`. Flag as community-maintained. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host n8n on?" | Free-text | e.g. `n8n.example.com`. Needed for `N8N_HOST` and `WEBHOOK_URL`. |
| tls | "Email for Let's Encrypt notices?" | Free-text | Only if we manage TLS ourselves |
| smtp | "Outbound email provider for password-reset/user-management?" | AskUserQuestion: Resend / SendGrid / Mailgun / Skip | Optional — only needed if you enable user management |
| db | "Use SQLite (default) or Postgres?" | AskUserQuestion: SQLite / Postgres | SQLite is fine for single-user. Postgres for teams / backups / HA. |
| db (if Postgres) | "Postgres connection: host, user, password, db name" | Free-text (password sensitive) | Or Claude provisions a sibling Postgres container |
| secrets | "Generate an N8N_ENCRYPTION_KEY?" | Confirm | Must be persistent — losing it bricks all encrypted credentials |

## Install methods (upstream-documented)

### 1. Docker (single container, SQLite) — from README

Source: https://github.com/n8n-io/n8n/blob/master/README.md#quick-start

```bash
docker volume create n8n_data
docker run -d --name n8n --restart unless-stopped \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e N8N_HOST=n8n.example.com \
  -e N8N_PROTOCOL=https \
  -e WEBHOOK_URL=https://n8n.example.com/ \
  -e GENERIC_TIMEZONE=UTC \
  docker.n8n.io/n8nio/n8n
```

Then front it with a reverse proxy (Caddy 2 auto-TLS is simplest).

### 2. Docker Compose with Postgres — from docs

Source: https://docs.n8n.io/hosting/installation/docker/ (upstream docs)

The upstream repo does **not** ship a canonical `docker-compose.yml`; compose examples live in docs. Shape:

```yaml
services:
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h localhost -U n8n -d n8n"]
      interval: 5s
      timeout: 5s
      retries: 10

  n8n:
    image: docker.n8n.io/n8nio/n8n
    restart: unless-stopped
    ports:
      - "127.0.0.1:5678:5678"
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
      N8N_HOST: ${N8N_HOST}
      N8N_PROTOCOL: https
      WEBHOOK_URL: https://${N8N_HOST}/
      N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
      GENERIC_TIMEZONE: ${TZ:-UTC}
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  postgres_data:
  n8n_data:
```

With `.env`:

```bash
N8N_HOST=n8n.example.com
POSTGRES_PASSWORD=$(openssl rand -hex 24)
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
TZ=UTC
```

### 3. npm / npx — dev only

```bash
npx n8n
```

Data lives in `~/.n8n/`. No process manager — don't use in production.

### 4. Kubernetes — community Helm chart

> ⚠️ **Community-maintained.** Upstream n8n does not publish a Helm chart. The most-active community chart is [8gears/n8n-helm-chart](https://github.com/8gears/n8n-helm-chart). Commands below are illustrative — verify the values at the version you pull.

```bash
helm repo add 8gears https://8gears.container-registry.com/chartrepo/library
helm install n8n 8gears/n8n --set n8n.encryption_key=... --set n8n.host=n8n.example.com
```

TODO: verify which community chart is most active at first-deploy time.

### 5. DigitalOcean 1-click Droplet

Source: https://marketplace.digitalocean.com/apps/n8n (published by n8n)

Creates a droplet with n8n + Caddy pre-installed. Point DNS at the droplet, run `sudo n8n-setup` for the domain. Upstream-blessed; the fastest path on DO.

## Software-layer concerns

### Key env vars

| Var | Required? | Purpose |
|---|---|---|
| `N8N_HOST` | yes (prod) | External hostname; affects generated URLs |
| `N8N_PROTOCOL` | yes (prod) | `http` or `https` |
| `WEBHOOK_URL` | yes (prod) | Public URL webhooks are served from; **trailing slash matters** |
| `N8N_ENCRYPTION_KEY` | yes | Encrypts stored credentials. **Persist it.** Changing it bricks all saved credentials. |
| `DB_TYPE` | no | `sqlite` (default) or `postgresdb` |
| `DB_POSTGRESDB_*` | if Postgres | host, port, database, user, password |
| `GENERIC_TIMEZONE` | no | e.g. `America/Los_Angeles`. Affects cron-trigger evaluation. |
| `N8N_SECURE_COOKIE` | no | `true` when behind HTTPS; default in newer versions |
| `N8N_EDITOR_BASE_URL` | no | Override editor URL (rare) |

Full env-var list: https://docs.n8n.io/hosting/configuration/environment-variables/

### Paths

| Thing | Path (in container) |
|---|---|
| Data dir | `/home/node/.n8n/` |
| SQLite DB | `/home/node/.n8n/database.sqlite` |
| Encryption-key-derived files | same dir |
| Custom nodes | `/home/node/.n8n/custom/` |

The entire data dir is in one volume — back that up (plus Postgres if used).

### Reverse proxy

n8n expects **HTTPS in production**. Terminate TLS at Caddy / Traefik / Nginx; forward to `127.0.0.1:5678`. Caddy example:

```caddy
n8n.example.com {
  reverse_proxy 127.0.0.1:5678
}
```

Caddy auto-renews Let's Encrypt certs. See `references/modules/tls.md`.

### Task runners / queues (scale-out)

For heavy workloads, n8n supports a queue-mode with Redis + worker containers. Single-node is fine for most self-hosts — queue mode only matters once you hit >1000 executions/day or long-running workflows. See https://docs.n8n.io/hosting/scaling/queue-mode/.

## Upgrade procedure

1. `docker compose pull` (or `docker pull docker.n8n.io/n8nio/n8n`).
2. Back up the data volume (and Postgres, if used):
   ```bash
   docker run --rm -v n8n_data:/src -v $PWD:/dst alpine tar czf /dst/n8n-$(date +%F).tgz -C /src .
   ```
3. `docker compose up -d` (or `docker stop n8n && docker rm n8n && docker run ...`). The container runs DB migrations on start.
4. Watch logs for migration completion: `docker logs -f n8n`. Expect `n8n ready on ::, port 5678`.
5. Pin major versions in compose — `n8nio/n8n:1` (not `:latest`) — to avoid surprise breaking changes.

Release notes: https://docs.n8n.io/release-notes/

## Gotchas

- **`N8N_ENCRYPTION_KEY` is precious.** Generate once, save it in your password manager, persist it via env var or the `~/.n8n/config` file. Losing it destroys every stored credential — you'll have to re-auth every integration.
- **`WEBHOOK_URL` trailing slash matters.** `https://n8n.example.com/` not `https://n8n.example.com`. External services posting to webhooks will otherwise hit a redirect.
- **Port 5678 isn't random — Node.js default ports are often blocked.** Always reverse-proxy; don't expose 5678 directly.
- **SQLite → Postgres migration is not automatic.** Export workflows + credentials (via n8n CLI `n8n export:workflow`) and re-import. Don't try to point a Postgres-configured n8n at an empty DB and expect data to appear.
- **`docker.n8n.io/n8nio/n8n` not `n8nio/n8n` on Docker Hub.** Upstream switched to their own registry; Docker Hub image is still published but the n8n.io registry is primary.
- **User management off by default.** First-time you visit `/`, n8n asks you to create an owner account. Access-control happens there, not via HTTP auth.
- **`N8N_SECURE_COOKIE=false` needed if serving over plain HTTP (dev).** In prod with TLS, leave it `true`.

## TODO — verify on subsequent deployments

- [ ] Official Helm chart status — confirm 8gears remains the most-active community option.
- [ ] DigitalOcean marketplace image — verify it's current (upstream publisher?).
- [ ] Queue mode wiring — first-run with Redis + worker.
- [ ] Backup script — shell a reusable one into `references/modules/backups.md`.
