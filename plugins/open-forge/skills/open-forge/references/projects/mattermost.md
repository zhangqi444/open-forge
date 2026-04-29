---
name: mattermost-project
description: Mattermost Team Edition recipe for open-forge. Apache-2.0 / AGPL-3.0 dual-licensed self-hostable Slack alternative (chat, calls, playbooks, boards). Canonical install is the upstream `mattermost/docker` repo — a Docker Compose stack (PostgreSQL + Mattermost + optional nginx TLS proxy). Also covers the Ubuntu `.deb` install, Gitlab Omnibus, Helm chart, and the Team Edition vs Enterprise Edition split. Includes TLS via bundled nginx, SiteURL hardening, and the admin bootstrap (first user to sign up becomes System Admin).
---

# Mattermost

Self-hosted team chat + collaboration platform (channels, DMs, threads, integrations, calls, playbooks, boards). Upstream (server): <https://github.com/mattermost/mattermost>. Docker deploy repo: <https://github.com/mattermost/docker>. Docs: <https://docs.mattermost.com>.

**License split.** Mattermost Team Edition (TE) is Apache-2.0. Mattermost Enterprise Edition (EE) adds LDAP, SAML, clustering, compliance exports, etc. and is AGPL-3.0 with an EE license overlay. Most selfh.st deploys run **TE**; this recipe focuses there.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`mattermost/docker`) | <https://github.com/mattermost/docker> | ✅ Recommended | The canonical self-host path. Ships Postgres + Mattermost + optional nginx TLS proxy. |
| Ubuntu `.deb` | <https://docs.mattermost.com/install/install-ubuntu.html> | ✅ | Bare-metal Ubuntu 22.04/24.04 + external Postgres. |
| RHEL / Debian tarball | <https://docs.mattermost.com/install/install-rhel.html> | ✅ | Manual install on RHEL-family. |
| Kubernetes (Helm + Operator) | <https://docs.mattermost.com/install/install-kubernetes.html> · <https://github.com/mattermost/mattermost-operator> | ✅ | Production K8s. Enterprise feature territory. |
| Preview Docker image (`mattermost/mattermost-preview`) | Docker Hub | ✅ | Quick tyre-kicking; uses SQLite, not for production. |
| GitLab Omnibus | `mattermost/mattermost-omnibus` | ⚠️ Deprecated | Was popular pre-2023; upstream now points at `mattermost/docker`. Avoid for new deploys. |
| Cloud (`cloud.mattermost.com`) | — | ✅ (commercial) | Out of scope for self-host. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| preflight | "Edition?" | `AskUserQuestion`: `Team Edition (free, Apache-2.0)` / `Enterprise Edition (AGPL-3.0 + license key)` | Changes image tag (`mattermost-team-edition` vs `mattermost-enterprise-edition`). |
| dns | "Domain (`MM_SITEURL`)?" | Free-text, e.g. `https://chat.example.com` | **Critical** — Mattermost requires a canonical SiteURL set correctly or push notifications, webhooks, and mobile clients misbehave. |
| tls | "TLS: bundled nginx, external reverse proxy, or Let's Encrypt via Mattermost itself?" | `AskUserQuestion` | The Docker repo includes an nginx profile; alternatively terminate at external Caddy/Traefik. |
| db | "Postgres version (default 15)?" | Free-text | Upstream supports 12+. Compose defaults to a bundled Postgres container. |
| smtp | "SMTP provider for notifications?" | `AskUserQuestion`: `Skip` / `SendGrid` / `Resend` / `Mailgun` / `Amazon SES` / `Generic` | Without SMTP, password resets + email notifications don't work. |
| storage | "File storage (local or S3)?" | `AskUserQuestion`: `Local volume` / `S3 (or compatible: MinIO, R2, Backblaze)` | Local for hobby; S3 for durable / scale. |
| admin | "First sysadmin email?" | Free-text | First user to sign up at `/signup_email` becomes System Admin by default. |

## Install — Docker Compose (upstream-recommended)

```bash
# 1. Clone the upstream docker repo
git clone https://github.com/mattermost/docker
cd docker

# 2. Create env file from template
cp env.example .env

# 3. Edit .env — key fields to change
#    DOMAIN=chat.example.com
#    POSTGRES_PASSWORD=$(openssl rand -base64 32)
#    MATTERMOST_IMAGE=mattermost-team-edition   (or mattermost-enterprise-edition)
#    MATTERMOST_IMAGE_TAG=release-9.11          (pin a version; check docker hub)
#    CALLS_PORT=8045
#    MM_SERVICESETTINGS_SITEURL=https://chat.example.com

$EDITOR .env

# 4. Create required directories with correct ownership
# Mattermost container runs as UID 2000 inside; bind mounts must be writable by that UID
mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
sudo chown -R 2000:2000 ./volumes/app/mattermost

# 5. Start the stack (without bundled nginx — use external reverse proxy)
docker compose -f docker-compose.yml -f docker-compose.without-nginx.yml up -d

# 6. OR: start WITH the bundled nginx TLS proxy
# Requires certs in ./volumes/web/cert/ (cert.pem + key-no-password.pem)
# docker compose -f docker-compose.yml -f docker-compose.nginx.yml up -d

# 7. Watch logs until "Server is listening on :8065"
docker compose logs -f mattermost
```

Then visit `https://chat.example.com/` → **Create Account** → the first account is auto-promoted to System Admin.

### Bundled nginx TLS

Upstream's `docker-compose.nginx.yml` runs a pre-configured nginx. You supply certs at `./volumes/web/cert/cert.pem` + `./volumes/web/cert/key-no-password.pem`. Either generate with certbot externally, or use Let's Encrypt DNS-01 via the upstream `scripts/issue-certificate.sh` helper (see repo README).

### External reverse proxy (Caddy)

Simpler for most open-forge deploys:

```caddy
chat.example.com {
    reverse_proxy mattermost:8065
}
```

Caddy handles Let's Encrypt automatically. Make sure `MM_SERVICESETTINGS_SITEURL=https://chat.example.com` matches.

## Install — Ubuntu `.deb` (bare metal)

Upstream provides a `.deb` for Ubuntu LTS:

```bash
# 1. Install Postgres separately
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib

sudo -u postgres psql <<SQL
  CREATE DATABASE mattermost;
  CREATE USER mmuser WITH PASSWORD 'strong-password';
  GRANT ALL PRIVILEGES ON DATABASE mattermost TO mmuser;
SQL

# 2. Download + install Mattermost .deb
MM_VERSION=9.11.0  # check https://github.com/mattermost/mattermost/releases
wget https://releases.mattermost.com/${MM_VERSION}/mattermost-${MM_VERSION}-linux-amd64.deb
sudo apt-get install -y ./mattermost-${MM_VERSION}-linux-amd64.deb

# 3. Configure /opt/mattermost/config/config.json
# Set SqlSettings.DataSource, ServiceSettings.SiteURL, FileSettings.Directory, SmtpSettings.*
sudo -u mattermost $EDITOR /opt/mattermost/config/config.json

# 4. Systemd unit is installed automatically
sudo systemctl enable --now mattermost
sudo systemctl status mattermost
sudo journalctl -u mattermost -f
```

Then front with nginx or Caddy for TLS.

## First-run — claim the System Admin account

**First user to sign up at `/signup_email` becomes System Admin.** Two consequences:

1. If Mattermost is on the public internet during first boot, anyone can claim root. Mitigate by either:
   - Firewalling access until you've claimed the account, OR
   - Setting `ServiceSettings.EnableUserCreation=false` before first `up`, creating the admin via CLI (`mmctl user create --system-admin …`), then re-enabling.
2. Additional admins are added via **System Console → Users → assign System Admin role**.

## Configuration

Config lives in `config.json`. In Docker, mounted at `/mattermost/config/config.json`. The Compose stack exposes a subset via env vars (prefix `MM_`):

| Env var | config.json key | Purpose |
|---|---|---|
| `MM_SERVICESETTINGS_SITEURL` | `ServiceSettings.SiteURL` | Canonical URL (critical for mobile clients + push notifications). |
| `MM_SQLSETTINGS_DRIVERNAME` | `SqlSettings.DriverName` | `postgres` (default in compose). |
| `MM_SQLSETTINGS_DATASOURCE` | `SqlSettings.DataSource` | Postgres conn string — compose builds this from POSTGRES_* env. |
| `MM_FILESETTINGS_DRIVERNAME` | `FileSettings.DriverName` | `local` or `amazons3`. |
| `MM_FILESETTINGS_AMAZONS3*` | S3 settings | Bucket, access key, secret, endpoint (for S3-compatible). |
| `MM_EMAILSETTINGS_SMTP*` | SMTP settings | Configure for password resets + notifications. |
| `MM_BLEVESETTINGS_INDEXDIR` | `BleveSettings.IndexDir` | Full-text search index location (inside mattermost-data volume by default). |

After editing `.env`, restart Mattermost:

```bash
docker compose up -d --force-recreate mattermost
```

## Admin CLI — `mmctl`

`mmctl` is the official admin CLI, bundled inside the container:

```bash
# Auth as local admin (uses the container's socket)
docker compose exec mattermost mmctl --local user list

# Common operations
docker compose exec mattermost mmctl --local user create --email alice@example.com --username alice --password 'strong-pw' --system-admin
docker compose exec mattermost mmctl --local team create --name engineering --display-name 'Engineering'
docker compose exec mattermost mmctl --local config set ServiceSettings.EnableUserCreation false
```

Works even when the Mattermost UI is locked down — useful for emergency admin recovery.

## Data layout

Bind-mounted into `./volumes/` by the upstream compose:

| Path (host) | Path (container) | Content |
|---|---|---|
| `./volumes/app/mattermost/config/` | `/mattermost/config/` | `config.json`, custom themes, plugins config. |
| `./volumes/app/mattermost/data/` | `/mattermost/data/` | Uploaded files (if `FileSettings.Driver=local`), user avatars. |
| `./volumes/app/mattermost/logs/` | `/mattermost/logs/` | Access + app logs. |
| `./volumes/app/mattermost/plugins/` | `/mattermost/plugins/` | Installed plugins (tarballs). |
| `./volumes/app/mattermost/client/plugins/` | `/mattermost/client/plugins/` | Plugin client assets. |
| `./volumes/app/mattermost/bleve-indexes/` | `/mattermost/bleve-indexes/` | Full-text search index (rebuildable). |
| `./volumes/db/` | (postgres data dir) | Postgres data. |

**Backup**: `pg_dump` Postgres + `tar` the bind mounts. Bleve indexes are rebuildable — skip them to save space.

```bash
# Postgres
docker compose exec postgres pg_dump -U mmuser mattermost > mm-$(date +%F).sql

# App data
sudo tar --exclude='*/bleve-indexes' -czf mm-data-$(date +%F).tar.gz volumes/app
```

## Upgrade procedure

```bash
# 1. Back up DB + volumes (see above).
# 2. Read release notes — https://docs.mattermost.com/upgrade/ and https://github.com/mattermost/mattermost/releases
# 3. Bump MATTERMOST_IMAGE_TAG in .env, then:
docker compose pull
docker compose up -d

# 4. Watch logs for migration completion
docker compose logs -f mattermost
# → "Server is listening on :8065"
```

**Upgrade paths are not unlimited-version-skip.** Mattermost supports upgrades from the previous ESR (extended-support release) and last two minor versions. Skipping major ESR boundaries (e.g. 7.x → 9.x without touching 8.x) is not tested. Read <https://docs.mattermost.com/upgrade/extended-support-release.html> first.

## Gotchas

- **SiteURL mismatch = broken push notifications + mobile clients + webhooks.** `MM_SERVICESETTINGS_SITEURL` must exactly match what users type — scheme + host + port (no trailing slash). `http://` vs `https://` mismatch is the #1 "Mattermost mobile app won't connect" cause.
- **First user to sign up becomes System Admin.** On public deploys, either firewall until claimed, or disable signup + create admin via `mmctl`.
- **Bind-mount ownership: UID 2000.** The Mattermost container runs as `mattermost` (UID 2000). Bind-mounted `./volumes/app/mattermost/*` must be owned by 2000:2000 or Mattermost fails to start with permission errors on the config/data dirs.
- **Upstream `mattermost/mattermost-preview` is NOT for production.** It uses SQLite. Use `mattermost-team-edition` or `mattermost-enterprise-edition` with Postgres.
- **Postgres `mem_limit: 16G` in upstream compose.** Fine for big deployments, wrong for a 4GB VPS. Lower to something sensible (`mem_limit: 2G`) or remove the limit.
- **Calls (voice/video) need dedicated UDP ports.** The plugin listens on `CALLS_PORT` (default 8045 TCP + 8443 UDP). Open both at the firewall; UDP is required for actual media. External reverse proxies generally don't proxy UDP — expose UDP directly on the host.
- **Plugins run as part of the Mattermost server process.** A bad plugin can crash the server. Install from the official Plugin Marketplace, not random GitHub repos.
- **ENABLE_OPENID_CONNECT requires EE.** SSO via SAML/LDAP/OpenID is Enterprise-only. TE supports email+password + GitLab-OAuth + Google-OAuth + Office365-OAuth natively.
- **TE vs EE image tags are NOT interchangeable post-migration.** Switching from TE to EE in place is OK (EE binary reads TE DB). Downgrading EE → TE is NOT supported — you'd need to export/re-import.
- **Bleve (full-text) index rebuilds are expensive.** For a busy team (>100 users), rebuilding can take hours. Back it up instead of rebuilding.
- **Push notifications require either Mattermost's hosted proxy (rate-limited for TE) or a self-hosted Push Proxy (HPNS/MHPNS).** The hosted proxy works out-of-box for TE with volume caps; for heavy use, either buy MHPNS or build the Push Proxy yourself.
- **MIT Apache vs AGPL split.** Core server is Apache-2.0 for TE code paths, AGPL-3.0 for EE code paths, plus a commercial license overlay for EE features. If you modify and redistribute EE-path code, AGPL-3.0 reciprocity applies.

## Links

- Server repo: <https://github.com/mattermost/mattermost>
- Docker deploy repo: <https://github.com/mattermost/docker>
- Docs: <https://docs.mattermost.com>
- Install guide index: <https://docs.mattermost.com/install/install-overview.html>
- Config reference: <https://docs.mattermost.com/configure/configuration-settings.html>
- `mmctl` docs: <https://docs.mattermost.com/manage/mmctl-command-line-tool.html>
- Upgrade guide: <https://docs.mattermost.com/upgrade/>
- ESR schedule: <https://docs.mattermost.com/upgrade/extended-support-release.html>
- Releases: <https://github.com/mattermost/mattermost/releases>
- Helm chart / Operator: <https://github.com/mattermost/mattermost-operator>
