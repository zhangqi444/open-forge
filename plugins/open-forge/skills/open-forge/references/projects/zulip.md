---
name: zulip-project
description: Zulip recipe for open-forge. Apache 2.0 open-source team chat server with threaded topics model — "channels + topics" (not just channels like Slack or Discord). Strong async-first UX, large orgs-in-a-room scale, plus full-history keyword search. Self-hosts on any Linux box. Two supported install paths - (1) "standard Zulip installer" (Debian/Ubuntu/RHEL — bare-metal, the officially recommended path) and (2) docker-zulip (first-party Docker Compose distribution under the Zulip org, currently v12.0, image `ghcr.io/zulip/zulip-server:12.0-0`). The older zulip/docker-zulip image at `hub.docker.com/r/zulip/docker-zulip` is supported through end of 11.x only — NEW deployments should use the ghcr.io image. Stack = Zulip app + Postgres + Redis + RabbitMQ + memcached + Nginx. Minimum 2GB RAM recommended.
---

# Zulip

Apache 2.0 open-source team chat + threaded collaboration. Upstream: <https://github.com/zulip/zulip>. Website: <https://zulip.com>. Self-hosting docs: <https://zulip.readthedocs.io>. Docker docs: <https://zulip.readthedocs.io/projects/docker/en/latest/>.

**What makes Zulip different:** channels + **topics**. Every message belongs to a channel AND a topic — so async conversations don't collide. If Slack is "channels are hallways," Zulip is "channels are rooms, topics are conversations within a room." Great for async / distributed / open-source teams; can feel over-structured for real-time chitchat crowds.

## Two install paths

| Path | Upstream | Recommended for | Docs |
|---|---|---|---|
| **Standard installer** (bare-metal on Debian 12/13, Ubuntu 22.04/24.04, RHEL 8/9) | `curl https://download.zulip.com/server/zulip-server-latest.tar.gz` | Most self-hosters. Easier upgrades, well-trodden path. | <https://zulip.readthedocs.io/en/latest/production/install.html> |
| **docker-zulip** (`ghcr.io/zulip/zulip-server`) | <https://github.com/zulip/docker-zulip> | Users with Docker / K8s-first infra. | <https://zulip.readthedocs.io/projects/docker/en/latest/> |

Upstream explicitly says: *"Deploying with Docker moderately increases the effort required to install, maintain, and upgrade a Zulip installation, compared with the standard Zulip installer."* If you don't have a strong reason to use Docker, use the standard installer.

## ⚠️ Docker image move (2024+)

| Image | Status | Versions |
|---|---|---|
| `ghcr.io/zulip/zulip-server` | ✅ **Current** | 12.0+ |
| `hub.docker.com/r/zulip/docker-zulip` | ⚠️ Legacy | Supported through end of 11.x only |

New deployments → use `ghcr.io/zulip/zulip-server:12.0-0`. Migration guide from 11.x docker-zulip: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-upgrading.html#upgrading-from-zulip-docker-zulip-11-x-and-earlier>.

## Features

- **Channels + topics** — the defining feature.
- **Search everything** — full history, full-text + keyword.
- **Threaded replies** within a topic.
- **Mobile (iOS + Android)**, desktop (Electron), web.
- **Custom emoji**, reactions, bot framework.
- **SAML / OIDC / LDAP / Google/GitHub/GitLab/Azure AD SSO**.
- **Integrations**: GitHub, GitLab, Jira, PagerDuty, Sentry, etc. (~100 built-in).
- **Bot API** for custom integrations.
- **Incoming-email integration** — email a channel.
- **Per-user DM + group DM**.
- **Formatted messages** (Markdown + code blocks + LaTeX math).
- **Export / import** to/from another Zulip instance.
- **Open-source mobile apps** (zulip-mobile).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Standard installer (bare-metal) | <https://zulip.readthedocs.io/en/latest/production/install.html> | ✅ Recommended | Any supported Linux box. |
| docker-zulip (Docker Compose) | <https://github.com/zulip/docker-zulip> | ✅ | Docker-first users. |
| Kubernetes (Helm chart, part of docker-zulip) | <https://github.com/zulip/docker-zulip/tree/main/helm> | ✅ | Kubernetes clusters. |
| Zulip Cloud (hosted) | <https://zulip.com> | Paid + free-tier | Don't self-host. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `standard-installer (bare-metal)` / `docker-compose` / `k8s-helm` / `zulip-cloud` | Drives section. |
| preflight | "Server RAM?" | Min 2 GB prod; 4 GB if building from source | Standard installer's recommendation. |
| dns | "External hostname?" | e.g. `zulip.example.com` | `SETTING_EXTERNAL_HOST`. Baked into invite URLs. |
| secrets | "Admin email?" | e.g. `admin@example.com` | `SETTING_ZULIP_ADMINISTRATOR`. Gets important notifications. |
| secrets | "Docker secrets (required in docker-compose)?" | multiple | `ZULIP__SECRET_KEY`, `ZULIP__POSTGRES_PASSWORD`, `ZULIP__MEMCACHED_PASSWORD`, `ZULIP__RABBITMQ_PASSWORD`, `ZULIP__REDIS_PASSWORD`, `ZULIP__EMAIL_PASSWORD`. |
| tls | "TLS?" | `AskUserQuestion`: `letsencrypt (auto, needs public DNS)` / `self-signed (dev)` / `byo-cert-pem` | Compose supports all three. |
| smtp | "Outgoing SMTP?" | multi-field | Required for invites, password reset, email-gateway integration. |
| auth | "Auth backends?" | `AskUserQuestion`: `email-password` / `google` / `github` / `gitlab` / `ldap` / `saml` / `oidc` / `azuread` | Multi-select; set `SETTING_AUTHENTICATION_BACKENDS`. |
| storage | "Volumes for persistence?" | Managed Docker volumes (default) | Compose uses named volumes; backup them. |

## Install — Standard installer (recommended path)

```bash
# Debian 12/13 / Ubuntu 22.04+ / RHEL 8+
wget https://download.zulip.com/server/zulip-server-latest.tar.gz
tar -xf zulip-server-latest.tar.gz

sudo ./zulip-server-*/scripts/setup/install \
  --certbot \
  --email="admin@example.com" \
  --hostname="zulip.example.com"
```

What the installer does:

- Installs Postgres + Redis + RabbitMQ + memcached + Nginx.
- Obtains a Let's Encrypt certificate.
- Sets up the Zulip application + systemd services.
- Prints a one-time link to create your first organization.

Open the link → create org → invite users. Done.

## Install — Docker Compose (docker-zulip)

The upstream docker-zulip repo uses Docker secrets (env-backed) + a base compose file + overlay files per use case (certbot / self-signed / http-only / backup-restore / etc.).

```bash
git clone https://github.com/zulip/docker-zulip.git
cd docker-zulip

# Set your settings + secrets in environment variables (or a .env file)
cat > .env <<EOF
SETTING_EXTERNAL_HOST=zulip.example.com
SETTING_ZULIP_ADMINISTRATOR=admin@example.com

# Secrets (auto-generate):
ZULIP__SECRET_KEY=$(openssl rand -hex 32)
ZULIP__POSTGRES_PASSWORD=$(openssl rand -hex 16)
ZULIP__MEMCACHED_PASSWORD=$(openssl rand -hex 16)
ZULIP__RABBITMQ_PASSWORD=$(openssl rand -hex 16)
ZULIP__REDIS_PASSWORD=$(openssl rand -hex 16)
ZULIP__EMAIL_PASSWORD=<smtp-password>
EOF

# First-time init (runs migrations + creates initial config)
docker compose pull
docker compose run --rm zulip app:init

# Start
docker compose up zulip --wait

# Create org creation link
./manage.py generate_realm_creation_link
# → open URL → create organization
```

See the step-by-step: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-getting-started.html>.

## TLS options

From the docker-zulip SSL how-to:

| Option | `CERTIFICATES` env var | Use case |
|---|---|---|
| Let's Encrypt (auto) | `letsencrypt` | Server has public DNS + port 80 open. Production. |
| Self-signed | `self-signed` | Dev / internal. Browser warning. |
| BYO cert | (not set; mount cert.pem + key.pem) | Existing PKI / reverse proxy handles TLS. |

Full reference: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-ssl.html>.

## Settings

`SETTING_*` env vars (prefix on the `zulip` service) map to Django settings. Key ones:

| Env var | Default | Purpose |
|---|---|---|
| `SETTING_EXTERNAL_HOST` | — | Public hostname (MUST set) |
| `SETTING_ZULIP_ADMINISTRATOR` | — | Admin email (MUST set) |
| `SETTING_EMAIL_HOST` | — | SMTP server |
| `SETTING_EMAIL_HOST_USER` | — | SMTP user |
| `SETTING_EMAIL_PORT` | `587` | |
| `SETTING_EMAIL_USE_TLS` | `True` | |
| `SETTING_AUTHENTICATION_BACKENDS` | `EmailAuthBackend` | Comma-separated list — `EmailAuthBackend`, `GoogleAuthBackend`, `GitHubAuthBackend`, `SAMLAuthBackend`, `LDAPAuthBackend`, `AzureADAuthBackend`, etc. |
| `SETTING_CUSTOM_WEB_CLIENT_INCOMING_WEBHOOK_RATE_LIMIT` | — | Webhook rate limits |

Full reference: <https://zulip.readthedocs.io/projects/docker/en/latest/reference/environment-vars.html>.

`SECRETS_*` / `ZULIP__*_PASSWORD` env vars back Docker secrets. See <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-secrets.html>.

## Data layout

Docker-zulip uses named Docker volumes. Per upstream:

| Volume | Content |
|---|---|
| `postgres_data` | All messages, users, streams, topics, reactions, subscriptions — the main DB |
| `rabbitmq_data` | Queue state (in-flight jobs) |
| `memcached_data` | Rebuildable cache |
| `redis_data` | Rate-limit counters, session store |
| `zulip_data` (uploads) | File uploads (images, attachments) |

**Backup priority:**

1. **`postgres_data` + uploads** — the entire chat history + files. Use `manage.py export` OR `pg_dump` + tar of uploads.
2. **Zulip secrets file** (`zulip-secrets.conf`) — without it, you can't decrypt existing data.
3. Redis / RabbitMQ / memcached — rebuildable.

Backup via `scripts/setup/backup-database` (installer) or `manage.py export_realm` (per-realm, more portable).

## Upgrade procedure

**Standard installer:**

```bash
wget https://download.zulip.com/server/zulip-server-latest.tar.gz
tar -xf zulip-server-latest.tar.gz
sudo -s
cd zulip-server-*
./scripts/upgrade-zulip zulip-server-*.tar.gz
```

**Docker Compose:**

```bash
# Update the image tag in docker-compose.yml / your overrides
docker compose pull
docker compose run --rm zulip app:init
docker compose up zulip --wait
```

Release notes: <https://zulip.readthedocs.io/en/stable/overview/changelog.html>.

**Always back up before major-version upgrades** (e.g. 11.x → 12.x). DB migrations are automatic but cross-major upgrades have occasionally needed manual steps.

## Gotchas

- **Zulip is heavyweight.** 2 GB RAM MIN for small deployments. Postgres + RabbitMQ + Redis + memcached + Nginx + Zulip = 5+ processes. Don't try to run on a 1 GB VPS.
- **Docker install explicitly discouraged by upstream** for casual self-hosters. Use the standard installer unless you have a reason.
- **docker-zulip image MOVED** from Docker Hub to GitHub Container Registry as of v12. New deployments use `ghcr.io/zulip/zulip-server`. Old Docker Hub image supported only through 11.x.
- **Does NOT support `docker-rootless` / `uDocker`.** Zulip needs root to set `ulimit` / open files limits (thousands of concurrent connections).
- **Postgres major-version upgrade inside the container** is Zulip's hardest upgrade scenario. Use `zulip-postgresql` image which bundles the right version.
- **Organization = "realm"** in Zulip terminology. One instance can host multiple realms (subdomain-based).
- **First-user-to-sign-up becomes owner** — protect the realm creation link; don't post publicly.
- **Channel creation policy** — in large orgs, restrict who can create channels (Admin only / members after N days). Otherwise channel sprawl.
- **Topic discipline** is Zulip's killer feature AND learning curve — users coming from Slack often don't understand topics at first. Require good topic names in guidelines.
- **Email gateway** (reply-to-email-and-post-to-channel) needs MX record + SMTP inbound — complex setup. Many skip it.
- **Search is fast** (Postgres full-text) but NOT fuzzy. Match exact terms.
- **Long-running messages (scroll through a year of topics)** can be slow on the web client. Mobile is fine. Client-side rendering bottleneck.
- **Video/voice calls** are NOT built-in. Zulip integrates with Jitsi / BigBlueButton / Zoom for calls (links).
- **File upload storage** defaults to local disk. For scale, configure S3: `SETTING_LOCAL_UPLOADS_DIR=None` + `SETTING_S3_AUTH_BUCKET=...` etc.
- **Export to Mattermost / Slack**: built-in importer works for Slack export ZIPs + Mattermost exports.
- **Slack import** loses some fidelity (DMs stay private, custom emoji migrate).
- **GDPR deletion** is supported — `manage.py delete_user`.
- **LDAPS + SAML setup** is non-trivial; expect a few hours of config. Worth doing for SSO.
- **Custom domains per realm** (`team1.example.com`, `team2.example.com`) requires wildcard DNS + wildcard TLS cert.
- **Zulip Cloud free tier** exists (up to 10 users, community-owned orgs) — for tiny orgs, hosted is easier than self-hosting.
- **Backups are Zulip's Achilles heel for docker users** — named volumes aren't backed up automatically. Script it.
- **Incoming webhooks**: plenty of built-in integrations — check `/api/v1/external/*` for payload URLs.
- **Outgoing webhook / bot user** — create a bot user in org settings, get API key, your bot posts as that user.
- **Not all slash commands** from Slack map to Zulip — `/me` works, `/giphy` doesn't (unless you add a bot).
- **Mobile push** uses Apple/Google — Zulip Cloud relays push notifications; self-hosted needs the Zulip Push Notification Service (free) OR pay Zulip to get push for self-hosted (subscription).
- **Self-hosted push notifications**: register at <https://push.zulipchat.com/> for the free service. Self-hosted that skips registration = no mobile push.
- **Python version**: standard installer pins Python 3.10+ (as of Zulip 12). Older distros unsupported.

## TODO — verify on subsequent deployments

- **Zulip v12.0 (2026-05-01) — re-verify before next deploy.** Per Self-Host Weekly 2026-05-01: end-to-end encrypted mobile notifications, media preview sizes, redesigned recent conversations view, new alt text image syntax, new video call provider options. Server install commands likely unchanged (Zulip's installer.py + recipe's `puppet apply` flow are stable across major versions), but config schema + `/etc/zulip/settings.py` keys for the new features may need additions. Re-fetch upstream's v12 release notes + settings reference before deploying.

## Links

- Upstream repo: <https://github.com/zulip/zulip>
- docker-zulip repo: <https://github.com/zulip/docker-zulip>
- Self-hosting docs (standard installer): <https://zulip.readthedocs.io/en/latest/production/install.html>
- Docker / Compose docs: <https://zulip.readthedocs.io/projects/docker/en/latest/>
- Compose getting started: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-getting-started.html>
- Compose SSL: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-ssl.html>
- Compose secrets: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-secrets.html>
- Compose settings: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-settings.html>
- Compose upgrading: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-upgrading.html>
- Helm / K8s: <https://zulip.readthedocs.io/projects/docker/en/latest/how-to/helm-getting-started.html>
- Environment vars reference: <https://zulip.readthedocs.io/projects/docker/en/latest/reference/environment-vars.html>
- Architecture overview: <https://zulip.readthedocs.io/en/latest/overview/architecture-overview.html>
- Changelog: <https://zulip.readthedocs.io/en/stable/overview/changelog.html>
- Docker image: <https://ghcr.io/zulip/zulip-server>
- Zulip Cloud: <https://zulip.com>
- Mobile push service: <https://zulip.com/help/mobile-notifications>
- Community chat (on Zulip!): <https://chat.zulip.org>
