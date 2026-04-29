---
name: gogs-project
description: Gogs recipe for open-forge. MIT-licensed self-hosted Git service written in Go — the "painless" single-binary alternative that predates Gitea (which is itself a fork of Gogs from 2016). Single static binary + SQLite/MySQL/Postgres/MSSQL. Covers the 5 upstream-blessed install paths — binary release, Docker (`gogs/gogs`), APT/DEB via package managers, Go source build, platform installers — plus the first-run `/install` web wizard that writes `conf/app.ini`.
---

# Gogs

MIT-licensed Go Git service. "A painless self-hosted Git service." Upstream: <https://github.com/gogs/gogs>. Docs home: <https://gogs.io>. Install docs: <https://gogs.io/docs/installation>.

Gogs is the original codebase that Gitea was forked from in 2016. The two projects have diverged — Gitea has more active development; Gogs has a smaller, more conservative scope and a single-maintainer model. If you're choosing today, **Gitea is the more active fork** for most use cases; Gogs is appropriate when you want a very lean, single-binary Git forge without the features Gitea has added (Actions, packages, etc.).

## What you get

- Web UI for repos + issues + PRs + wiki + releases
- Access via SSH, HTTP(S), Git LFS
- PostgreSQL / MySQL / SQLite / MSSQL / TiDB backends
- Webhooks (Slack, Discord, Dingtalk, generic)
- Auth: local, SMTP, LDAP, reverse-proxy header, GitHub OAuth, 2FA
- ~35MB single Go binary, runs on a $5 VPS or a Raspberry Pi (upstream's own framing)

Default ports: `:3000` HTTP, `:22` SSH (configurable).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Binary release | <https://gogs.io/docs/installation/install_from_binary> · <https://github.com/gogs/gogs/releases> | ✅ Recommended | The upstream-blessed install. Static binary, extract and run. |
| Docker (`gogs/gogs`) | <https://github.com/gogs/gogs/tree/main/docker> · <https://hub.docker.com/r/gogs/gogs> | ✅ | Most common self-host shape. |
| Package manager (Arch, FreeBSD, Gentoo, NixOS) | <https://gogs.io/docs/installation/install_from_packages> | ⚠️ Community-maintained | If you prefer your distro's package. |
| Build from source | <https://gogs.io/docs/installation/install_from_source> | ✅ | Custom builds; Go 1.21+ required. |
| Cloud marketplaces (Cloudron / YunoHost / alwaysdata) | <https://gogs.io/docs/installation> | ⚠️ Partner-maintained | One-click deploys on managed platforms. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method? (binary / docker / source / package-manager)" | `AskUserQuestion` | Drives section. |
| platform | "OS + arch?" | Free-text (Linux, macOS, Windows, ARM) | Binary install asset selection. |
| db | "Database backend?" | `AskUserQuestion`: `SQLite` / `MySQL` / `Postgres` / `MSSQL` / `TiDB` | SQLite is fine for small / solo; Postgres/MySQL for teams. |
| dns | "Public domain?" | Free-text | For `[server] DOMAIN` + `[server] ROOT_URL`. |
| tls | "TLS? (reverse proxy / Gogs built-in / skip)" | `AskUserQuestion` | Gogs can serve HTTPS directly, but reverse proxy is standard. |
| ssh | "SSH server mode? (built-in / host OpenSSH)" | `AskUserQuestion` | Built-in = Gogs listens on a port. Host = users `ssh git@host` and Gogs serves via git-shell. |
| admin | "Initial admin username + email?" | Free-text | First `/install` wizard creates this. |

## Install — Binary

```bash
# 1. Create a dedicated system user (recommended)
sudo adduser --system --shell /bin/bash --gecos 'Gogs' --group --disabled-password --home /home/git git

# 2. Download binary (check https://github.com/gogs/gogs/releases for current version)
GOGS_VERSION=0.13.3
ARCH=linux_amd64  # or linux_arm64, darwin_amd64, windows_amd64, raspi2
curl -L -o /tmp/gogs.tar.gz \
  "https://dl.gogs.io/${GOGS_VERSION}/gogs_${GOGS_VERSION}_${ARCH}.tar.gz"

# 3. Extract to /home/git/gogs
sudo tar -xzf /tmp/gogs.tar.gz -C /home/git
sudo chown -R git:git /home/git/gogs

# 4. First run (as git user)
sudo -u git bash -c 'cd /home/git/gogs && ./gogs web'
# → listens on http://0.0.0.0:3000
# → visit it, complete the /install wizard (sets up DB + first admin)
```

### Systemd unit

```ini
# /etc/systemd/system/gogs.service
[Unit]
Description=Gogs
After=network.target
# If using MySQL: After=mysql.service
# If using Postgres: After=postgresql.service

[Service]
Type=simple
User=git
Group=git
WorkingDirectory=/home/git/gogs
ExecStart=/home/git/gogs/gogs web
Restart=always
RestartSec=5s
Environment=USER=git HOME=/home/git

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now gogs
sudo systemctl status gogs
sudo journalctl -u gogs -f
```

## Install — Docker

```yaml
# compose.yaml
services:
  gogs:
    image: gogs/gogs:latest       # pin a version tag in production, e.g. 0.13
    container_name: gogs
    restart: unless-stopped
    ports:
      - "3022:22"        # SSH — avoid host :22 clash
      - "3000:3000"      # HTTP
    volumes:
      - ./gogs-data:/data
    depends_on:
      - db
  db:
    image: postgres:16
    container_name: gogs-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: gogs
      POSTGRES_USER: gogs
      POSTGRES_PASSWORD: ${GOGS_DB_PASSWORD}
    volumes:
      - ./gogs-db:/var/lib/postgresql/data
```

Create `.env` with `GOGS_DB_PASSWORD=<generated>`. `docker compose up -d`.

Visit `http://localhost:3000` — the `/install` wizard appears on first boot. Point Gogs at `db:5432`, user `gogs`, password from env, DB name `gogs`. Create the first admin.

After install, config lives at `./gogs-data/gogs/conf/app.ini` on the host.

## First-run `/install` wizard

The first HTTP request lands on `/install`. You pick:

| Field | Typical value |
|---|---|
| Database Type | `SQLite3` (single-user), `MySQL`, `PostgreSQL`, `MSSQL`, `TiDB` |
| Host / User / Password / Database Name | DB connection details |
| Application Name | e.g. `My Gogs` |
| Repository Root Path | `/home/git/gogs-repositories` (Linux) or `/data/git/gogs-repositories` (Docker) |
| Run User | `git` (Linux) or `git` (Docker) |
| Domain | e.g. `gogs.example.com` |
| SSH Port | `22` (Linux host SSH) or `22` inside container + port-mapped to e.g. `3022` |
| HTTP Port | `3000` |
| Application URL | `https://gogs.example.com/` |
| Log Path | `/home/git/gogs/log` |

Optional: SMTP, register captcha, server/mail/notifier settings. Can be edited later in `app.ini`.

After submit, Gogs writes `custom/conf/app.ini` and restarts. The next page prompts to create the **first admin user** — do this immediately; leaving it blank means the first person to sign up in future becomes admin.

## Configuration

`app.ini` is the source of truth. Key sections:

```ini
[server]
DOMAIN           = gogs.example.com
HTTP_PORT        = 3000
ROOT_URL         = https://gogs.example.com/
SSH_DOMAIN       = gogs.example.com
SSH_PORT         = 22

[database]
TYPE             = postgres
HOST             = 127.0.0.1:5432
NAME             = gogs
USER             = gogs
PASSWORD         = ...

[security]
SECRET_KEY       = (generated — do not change without DB migration)
INSTALL_LOCK     = true        # set to true after first-run; prevents re-running /install

[service]
DISABLE_REGISTRATION = true    # set after creating admin for private forges
REQUIRE_SIGNIN_VIEW  = true    # private mode — forces login to view anything

[mailer]
ENABLED   = true
HOST      = smtp.example.com:587
FROM      = "Gogs <gogs@example.com>"
USER      = ...
PASSWD    = ...
```

Full reference: <https://gogs.io/docs/advanced/configuration_cheat_sheet>.

Restart after edits:

```bash
sudo systemctl restart gogs        # binary
docker compose restart gogs        # docker
```

## Reverse proxy (nginx example)

```nginx
server {
    listen 443 ssl http2;
    server_name gogs.example.com;
    ssl_certificate     /etc/letsencrypt/live/gogs.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/gogs.example.com/privkey.pem;

    client_max_body_size 500M;   # for large LFS / git pushes
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

In `app.ini`, set `[server] ROOT_URL = https://gogs.example.com/` + `[server] OFFLINE_MODE = true` if you don't want CDN-loaded assets.

## Upgrade procedure

### Binary

```bash
# 1. Back up DB + repositories + custom/conf/app.ini
sudo systemctl stop gogs
sudo -u git pg_dump gogs > gogs-$(date +%F).sql   # or mysqldump / sqlite3 backup
sudo tar -czf gogs-repos-$(date +%F).tar.gz /home/git/gogs-repositories
sudo cp /home/git/gogs/custom/conf/app.ini /home/git/app.ini.$(date +%F)

# 2. Download new binary, swap it in place
curl -L -o /tmp/gogs.tar.gz https://dl.gogs.io/0.13.4/gogs_0.13.4_linux_amd64.tar.gz
sudo tar -xzf /tmp/gogs.tar.gz -C /home/git --overwrite

# 3. Start — DB migrations (if any) run automatically
sudo systemctl start gogs
sudo journalctl -u gogs -f
```

### Docker

```bash
docker compose pull
docker compose up -d
```

Gogs minor-version upgrades are usually drop-in. Major jumps (0.11 → 0.12, 0.12 → 0.13) occasionally change config format — check <https://github.com/gogs/gogs/blob/main/CHANGELOG.md> before upgrading.

## Gotchas

- **Gitea is probably a better choice today.** Gogs development is slow compared to Gitea (which forked Gogs in 2016 and has added Actions, packages, OCI registry, much broader auth). Pick Gogs if you deliberately want lean, single-maintainer scope; otherwise Gitea is the more battle-tested fork.
- **`INSTALL_LOCK = true`** must be in `app.ini` after first-run. If it's `false` or missing and the install page is exposed, any visitor can re-run `/install` against your DB and potentially wipe it.
- **`DISABLE_REGISTRATION = true`** after creating the admin account, for private forges. Default is open registration.
- **SECRET_KEY is generated once** and used for all user sessions + 2FA secrets. Changing it invalidates all sessions and breaks 2FA for existing users.
- **SSH on port 22 conflict.** The binary install typically runs as user `git` and uses the host's OpenSSH (`git@host:repo.git` works because OpenSSH → `git` user → `~/.ssh/authorized_keys` → Gogs hook). The Docker install maps container `:22` to a non-standard host port (e.g. `3022`) — clients need `ssh://git@host:3022/user/repo.git`.
- **Git LFS needs its own config block.** `[lfs] ENABLED = true` + `SECRET = ...`. Not on by default.
- **Large pushes time out behind reverse proxies.** Set `client_max_body_size` (nginx) / request-size limits high. Also `[server] HTTP_ADDR` + SSH for fast-path big pushes.
- **Database type mismatches silently fail.** If you change `[database] TYPE` in `app.ini` post-install, Gogs uses the new DB but your data stays in the old one. Migrate with `gogs migrate` or `gogs admin dump` + restore.
- **Webhooks to internal IPs** are allowed by default. For multi-tenant deploys, configure `[webhook] SKIP_TLS_VERIFY` + firewall policies carefully.
- **Backup = `gogs backup` + DB dump.** Gogs ships a `./gogs backup` subcommand that tars repos + DB dump + app.ini. Run regularly.
- **Docker 0.11.91+ image uses `/data/git` mount.** Older images used `/gogs`. Migrating host-volume mounts between versions can silently lose data — verify paths match the image you're upgrading to.

## Links

- Upstream repo: <https://github.com/gogs/gogs>
- Install docs: <https://gogs.io/docs/installation>
- Configuration cheat sheet: <https://gogs.io/docs/advanced/configuration_cheat_sheet>
- Troubleshooting: <https://gogs.io/asking/troubleshooting>
- Docker image: <https://hub.docker.com/r/gogs/gogs>
- Discussions forum: <https://github.com/gogs/gogs/discussions>
- Releases: <https://github.com/gogs/gogs/releases>
- Comparison with Gitea: <https://docs.gitea.com/installation/comparison>
