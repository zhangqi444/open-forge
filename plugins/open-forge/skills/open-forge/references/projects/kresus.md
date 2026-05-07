---
name: kresus
description: Kresus recipe for open-forge. Self-hosted open-source personal finance manager. Bank account aggregation via Woob, transaction tagging, balance tracking, budget analysis. Node.js + Woob, Docker or npm install. Source: https://github.com/kresusapp/kresus
---

# Kresus

Open-source self-hosted personal finance manager. Aggregates bank account data via Woob (formerly Weboob), tracks transactions, applies tags and categories, monitors balance, and provides budget analysis. No external SaaS — your financial data stays on your server. Node.js + Woob. AGPL-3.0 licensed.

Upstream: <https://github.com/kresusapp/kresus> | Docs: <https://kresus.org/en/install.html>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker | `bnjbvr/kresus` — includes Woob; recommended |
| Linux | npm (Node.js) | Requires Woob installed separately |
| ArchLinux | pacman | `pacman -Syu kresus` (community-maintained) |
| Any | YunoHost | Level 7 app |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 9876 |
| config | Data directory | Persists Kresus DB and user data |
| config | Woob directory | Local Woob clone (shared across restarts) |
| config | config.ini path | Database and server settings |
| config (optional) | LOCAL_USER_ID | UID to run container as (prevents root execution) |

## Software-layer concerns

### Architecture

- **Kresus** (Node.js) — web app + API server
- **Woob** — Python library that scrapes/connects to bank websites; bundled in Docker image; updated at each container boot
- Database: SQLite (default) or PostgreSQL/MySQL (via config.ini)

### config.ini key settings

```ini
[kresus]
port = 9876
host = 127.0.0.1
# secret is auto-generated if empty
secret =

[db]
# SQLite (default)
type = sqlite
sqlite_path = /home/user/data/kresus.sqlite

# PostgreSQL alternative:
# type = postgres
# host = localhost
# port = 5432
# name = kresus
# username = kresus
# password = yourpassword
```

Full config reference: https://kresus.org/en/doc.html

### Data dirs (Docker)

| Host path | Container path | Description |
|---|---|---|
| /opt/kresus/data | /home/user/data | Kresus database and user data |
| /opt/kresus/woob | /woob | Woob installation (update with git pull) |
| /opt/kresus/config.ini | /opt/config.ini | Configuration file |

## Install — Docker

```bash
mkdir -p /opt/kresus/{data,woob}
touch /opt/kresus/config.ini

# Edit config.ini — at minimum set db path
cat > /opt/kresus/config.ini << 'EOF'
[kresus]
port = 9876

[db]
type = sqlite
sqlite_path = /home/user/data/kresus.sqlite
EOF

# Clone Woob (master branch = most up-to-date bank modules)
git clone https://gitlab.com/woob/woob.git /opt/kresus/woob

# Run
docker run -p 127.0.0.1:9876:9876 \
  -e LOCAL_USER_ID=$(id -u) \
  --restart unless-stopped \
  -v /opt/kresus/data:/home/user/data \
  -v /opt/kresus/woob:/woob \
  -v /opt/kresus/config.ini:/opt/config.ini \
  -v /etc/localtime:/etc/localtime \
  --name kresus \
  -d bnjbvr/kresus
```

> Deploy behind a reverse proxy with TLS — Kresus docs warn against exposing port 9876 directly.

## Upgrade procedure

```bash
# Update Woob (on host, shared volume)
git -C /opt/kresus/woob pull

# Update Kresus container
docker pull bnjbvr/kresus
docker rm -f kresus
# Re-run docker run command
```

## Gotchas

- **Woob is the critical dependency** — Woob modules scrape bank websites. Banks change their UIs frequently, so Woob modules need regular updates. Kresus restarts the Woob update process at each container boot; check container logs if bank connections fail.
- Use `-p 127.0.0.1:9876:9876` (not `0.0.0.0`) behind a reverse proxy — exposing the port publicly without authentication is a significant security risk since this app holds bank credentials.
- `LOCAL_USER_ID` should be set to your host UID (`id -u`) — prevents the container from running as root and ensures volume permissions work correctly.
- Bank support varies by country — Woob has modules for many European banks but coverage differs. Check https://woob.tech/applications/bank for module list.
- SQLite is fine for single-user; use PostgreSQL for better reliability and concurrent access.

## Links

- Source: https://github.com/kresusapp/kresus
- Documentation: https://kresus.org/en/doc.html
- Install guide: https://kresus.org/en/install.html
- Docker install: https://kresus.org/en/install-docker.html
- Woob (bank modules): https://woob.tech
