# Loomio

Collaborative decision-making tool for teams and organizations. Loomio enables structured group discussions, proposals, polls, and binding decisions — used by co-ops, NGOs, and distributed teams. It supports threads, outcomes, subgroups, and email notifications.

**Official site:** https://www.loomio.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Ubuntu VPS | Docker Compose | Official `loomio-deploy` repo; recommended install |
| Any Linux host | Docker Compose | Requires public domain + SMTP |

---

## Inputs to Collect

### Phase 1 — Planning
- Public domain name (e.g. `loomio.example.com`) — required; Let's Encrypt TLS is auto-provisioned
- SMTP credentials for email notifications and reply-by-email
- CNAME: `hocuspocus.loomio.example.com → loomio.example.com` (for collaborative editing)
- MX record pointing to your domain (for reply-by-email)
- Server: Ubuntu LTS, public IP, ≥1 GB RAM

### Phase 2 — Deployment
- `.env` file with `CANONICAL_HOST`, `LOOMIO_CONTAINER_IMAGE`, `SECRET_COOKIE_TOKEN`, SMTP settings
- Let's Encrypt email address

---

## Software-Layer Concerns

### Deployment via loomio-deploy

```bash
git clone https://github.com/loomio/loomio-deploy.git
cd loomio-deploy
cp .env-example .env
# Edit .env: set CANONICAL_HOST, SMTP, SECRET_COOKIE_TOKEN, etc.
docker compose up -d
```

### Docker Compose Architecture

| Service | Purpose |
|---------|---------|
| `app` | Rails web application |
| `worker` | Sidekiq background jobs |
| `db` | PostgreSQL |
| `redis` | Action Cable / job queues |
| `nginx-proxy` | TLS termination + reverse proxy |
| `nginx-proxy-acme` | Let's Encrypt certificate issuance |
| `hocuspocus` | Collaborative real-time editing server |

### Key `.env` Variables
| Variable | Description |
|----------|-------------|
| `CANONICAL_HOST` | Public domain (e.g. `loomio.example.com`) |
| `LOOMIO_CONTAINER_IMAGE` | Docker image name |
| `LOOMIO_CONTAINER_TAG` | Image tag / version |
| `SECRET_COOKIE_TOKEN` | Long random secret for session cookies |
| `SMTP_SERVER`, `SMTP_PORT` | SMTP host and port |
| `SMTP_USERNAME`, `SMTP_PASSWORD` | SMTP credentials |
| `REPLY_HOSTNAME` | Domain for reply-by-email (often same as CANONICAL_HOST) |

### Data Volumes (host-mounted)
- `./uploads` — user uploaded files
- `./storage` — ActiveStorage blobs
- `./files` — public static files
- `./plugins` — optional plugin directory

---

## Upgrade Procedure

```bash
cd loomio-deploy
git pull
docker compose pull
docker compose up -d
docker compose run app rails db:migrate
```

Review release notes at https://github.com/loomio/loomio/releases before upgrading major versions.

---

## Gotchas

- **Public domain required** — Let's Encrypt TLS is baked into the deploy stack; purely LAN installs require custom TLS setup.
- **CNAME for hocuspocus** must exist before starting — the collaborative editor (`hocuspocus.loomio.example.com`) is a separate subdomain.
- **MX record** is needed for reply-by-email functionality; without it, email-based replies won't work.
- **`SECRET_COOKIE_TOKEN`** must be a long (≥128 char) random string; changing it invalidates all existing sessions.
- **Reply-by-email** requires your SMTP provider to accept inbound mail or a separate inbound mail processor.
- **Root access required** on the host for Docker installation per the official guide.
- Loomio is a Rails app — asset precompilation runs on first boot; allow extra startup time.

---

## References
- Deploy repo: https://github.com/loomio/loomio-deploy
- App repo: https://github.com/loomio/loomio
- Docs: https://help.loomio.com/en/policy/self_hosting.html
