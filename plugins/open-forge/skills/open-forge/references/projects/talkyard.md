---
name: talkyard
description: Talkyard recipe for open-forge. Open-source community forum + Q&A + chat platform. Based on upstream docs at https://github.com/debiki/talkyard and https://github.com/debiki/talkyard-prod-one
---

# Talkyard

Open-source community discussion platform — a hybrid of StackOverflow, Slack, Discourse, Reddit, and Disqus blog comments. Supports threaded forums, Q&A with accepted answers, idea voting, chat channels, and embedded blog comments. Upstream: <https://github.com/debiki/talkyard>

Self-hosting guide: <https://github.com/debiki/talkyard-prod-one>. Demo: <https://www.talkyard.io/forum/latest>

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (talkyard-prod-one) | <https://github.com/debiki/talkyard-prod-one> | ✅ | Single-server production deployment |
| Talkyard.io hosted | <https://www.talkyard.io> | ✅ | Managed hosting — out of scope for open-forge |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Domain for your Talkyard forum?" | Free-text | All |
| preflight | "Admin email address?" | Free-text | All |
| smtp | "Which outbound email provider?" | `AskUserQuestion`: Mailgun / Sendgrid / SMTP / Skip | All (required for notifications, invites) |
| smtp | "SMTP host, port, username, password?" | Free-text | If SMTP chosen |

## Software-layer concerns

**Services (Docker Compose):**
- `web` — Nginx reverse proxy
- `app` — Scala/Play application server
- `cache` — Redis
- `rdb` — PostgreSQL
- `search` — Elasticsearch
- `certgen` — Let's Encrypt cert provisioning

**Config paths:**
- `.env` — main configuration (domain, SMTP, secrets)
- `conf/` — Nginx and app config overrides
- `volumes/` — data volumes for Postgres, Elasticsearch, Redis, uploads

**Data dirs:**
- `/opt/talkyard/volumes/rdb/` — PostgreSQL data
- `/opt/talkyard/volumes/es/` — Elasticsearch data
- `/opt/talkyard/volumes/pub-files/` — uploaded files

## Install — Docker Compose (talkyard-prod-one)

> **Source:** <https://github.com/debiki/talkyard-prod-one>

### Prerequisites

- Linux server (Ubuntu 22.04 LTS recommended), 1+ CPU, 2+ GB RAM
- Docker CE 20.10+ and Docker Compose v2
- Ports 80 and 443 open
- DNS A-record pointing to the server

### Install

```bash
# 1. Clone the production stack
sudo git clone https://github.com/debiki/talkyard-prod-one.git /opt/talkyard
cd /opt/talkyard

# 2. Copy example config
sudo cp .env.example .env

# 3. Edit .env with your values
sudo nano .env
# Required: HOSTNAME, GLOBALS__BECOME_OWNER_EMAIL, play.http.secret.key (generate random)
# SMTP settings if you have a provider

# 4. Generate secret key
openssl rand -hex 64  # paste into play.http.secret.key

# 5. Start services
sudo docker compose up -d

# 6. Tail logs to confirm startup
sudo docker compose logs -f
```

After startup, visit `https://<HOSTNAME>` to claim the owner account with the email you configured in `GLOBALS__BECOME_OWNER_EMAIL`.

### SMTP configuration

In `.env`:

```dotenv
GLOBALS__emailSmtpHost=smtp.mailgun.org
GLOBALS__emailSmtpPort=587
GLOBALS__emailSmtpUserName=postmaster@<your-domain>
GLOBALS__emailSmtpPassword=<password>
GLOBALS__emailFromAddress=noreply@<your-domain>
```

### Let's Encrypt TLS

Talkyard's `certgen` service handles certificate provisioning automatically when `HOSTNAME` is set and DNS resolves. No manual cert steps needed.

## Upgrade procedure

```bash
cd /opt/talkyard
sudo git pull
sudo docker compose pull
sudo docker compose up -d
sudo docker compose logs -f  # watch for migration completion
```

Talkyard runs DB migrations automatically on startup. Wait for logs to show "Server started" before assuming the upgrade succeeded.

## Gotchas

- **Elasticsearch memory:** ES requires at least 1GB JVM heap; set `vm.max_map_count=262144` on the host (`sysctl -w vm.max_map_count=262144` + add to `/etc/sysctl.conf`). Without this, Elasticsearch exits with a bootstrap check failure.
- **First owner claim window:** After install, the first person to visit and sign up with the configured `BECOME_OWNER_EMAIL` becomes the owner. Do this immediately — before sharing the link.
- **Email is essential:** Talkyard sends email for invites, notifications, and login (when using passwordless email login). Configure SMTP before going live.
- **Embedded comments:** Talkyard can replace Disqus for blog comments — embed via a JavaScript snippet. Requires CORS config in `.env` (`allowEmbeddingFrom`).
- **Resource-heavy:** Runs PostgreSQL + Redis + Elasticsearch + a JVM app server. Requires ≥ 2 GB RAM; 4 GB recommended for real traffic.
- **Custom domain for embedded comments:** If using `www.talkyard.io` domain for embedded comments but self-hosting, embedded origin config must match exactly.

## Links

- Upstream source: <https://github.com/debiki/talkyard>
- Self-host guide (talkyard-prod-one): <https://github.com/debiki/talkyard-prod-one>
- Documentation: <https://docs.talkyard.io>
- Demo: <https://insightful.demo.talkyard.io>
