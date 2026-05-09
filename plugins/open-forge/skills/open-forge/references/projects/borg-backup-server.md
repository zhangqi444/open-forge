---
name: borg-backup-server
description: Recipe for Borg Backup Server — a self-hosted BorgBackup management platform with a web UI, agent-based architecture, and Docker support.
---

# Borg Backup Server

Self-hosted web application for centrally managing BorgBackup across multiple endpoints (Linux, Mac, Windows). A lightweight agent polls the server over HTTPS for tasks, backs up over SSH, and reports progress back — no inbound connections from server to endpoints required. Upstream: https://github.com/marcpope/borgbackupserver. Official site: https://www.borgbackupserver.com/

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended — single container bundles MariaDB + ClickHouse. Web UI on port 8080, agent SSH on port 2222. |
| Ubuntu 22.04+ (bare-metal/VM) | Bash installer | curl install script handles Apache, MySQL, SSL, cron. Non-Docker path; see upstream Wiki. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What hostname or IP will agents use to reach this server?" | Free-text | Becomes APP_URL. Must be reachable from all backup endpoints. |
| preflight | "Which port for the web UI?" | Integer, default 8080 | WEB_PORT env var. |
| preflight | "Which port for agent SSH connections?" | Integer, default 2222 | SSH_PORT env var. Must be reachable from all endpoints. |
| preflight | "Where to store backup data — Docker-managed volume or a host bind-mount path?" | Choice | Bind mount recommended for large backup sets on dedicated storage. |
| optional | "Initial admin password?" | Free-text (sensitive) | Set via ADMIN_PASS. If omitted, auto-generated and shown in container logs on first run. |
| optional | "Host UID/GID for volume permissions?" | Two integers | Set PUID/PGID when using bind mounts; find with: id -u && id -g |

## Software-layer concerns

All runtime data (MariaDB database, borg repositories, SSH keys) lives under /var/bbs inside the container, mapped to the bbs-data volume or your bind-mount path.

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| APP_URL | http://localhost:8080 | Public URL agents use to reach the server. Required — set to the server's hostname/IP. |
| SSH_PORT | 2222 | Host port for agent SSH connections (BorgBackup data plane). |
| WEB_PORT | 8080 | Host port for the web UI and API. |
| ADMIN_PASS | (auto-generated) | Initial admin password. Only effective on first run. |
| PUID / PGID | 33 / 33 | UID/GID for the app process. Match host directory owner for bind-mount compatibility. |
| MYSQL_PUID / MYSQL_PGID | 100 / 100 | UID/GID for MariaDB. |
| CH_PUID / CH_PGID | 999 / 999 | UID/GID for ClickHouse (file catalog queries). |

### Ports

- Container port 80 → host WEB_PORT: web UI + agent control plane
- Container port 22 → host SSH_PORT: borg data plane for agent connections

## Deploy (Docker Compose)

```bash
# 1. Fetch upstream compose file
curl -sO https://raw.githubusercontent.com/marcpope/borgbackupserver/main/docker-compose.yml

# 2. Create .env
cat > .env << 'EOF'
APP_URL=https://backups.example.com
SSH_PORT=2222
WEB_PORT=8080
# ADMIN_PASS=your-initial-password  # omit to auto-generate
EOF

# 3. Start
docker compose up -d

# 4. Check logs for auto-generated admin password if ADMIN_PASS was not set
docker compose logs bbs | grep -i "admin\|password"
```

Open http://<host>:8080 and complete the setup wizard.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

The container handles database migrations on startup. One-click upgrade for the server software and all registered agents is also available from the web UI under Settings > Upgrade.

## Gotchas

- APP_URL must be the public hostname/IP — agents use this URL to poll for tasks. localhost only works when agents run on the same machine. Include the port if non-standard.
- SSH port must be open to all endpoints — BorgBackup data transfers go over SSH on SSH_PORT. Firewalls must allow inbound connections from agent machines to this port.
- Bind-mount and PUID/PGID — if using a bind mount for /var/bbs, set PUID/PGID to match the host directory's owner UID/GID to avoid permission errors (especially on btrfs/NAS). Changing these after first run triggers automatic ownership migration.
- Admin password is first-run only — ADMIN_PASS is only applied during container initialization. Use the web UI's user management to change it afterward.
- ClickHouse memory overhead — the container bundles ClickHouse for fast file-tree browsing. Adds approximately 200–400 MB of memory usage.
- S3 offsite sync — rclone is bundled in the container. Configure via web UI under Settings > S3 Offsite.
- Behind a reverse proxy — set APP_URL to the public https:// URL. Place web UI behind HTTPS (nginx, Caddy, Traefik); the SSH port must remain directly accessible.

## Links

- GitHub README: https://github.com/marcpope/borgbackupserver
- Docker Hub image: https://hub.docker.com/r/marcpope/borgbackupserver
- Docker Installation guide: https://github.com/marcpope/borgbackupserver/wiki/Docker-Installation
- Full documentation Wiki: https://github.com/marcpope/borgbackupserver/wiki
