# Guardian (Plex Security)

> Security and management platform for Plex Media Server. Monitor streaming activity in real-time, enforce granular access controls (IP-based, schedule-based, concurrent stream limits), and automatically block unapproved devices. Sends alerts via SMTP or Apprise (100+ services). Includes a self-service user portal where Plex users can view their devices.

**Official URL:** https://github.com/HydroshieldMKII/Guardian

> ⚠️ **Project status:** Feature-complete; looking for a maintainer. Security patches may be slow. Do not expose to the public internet without a reverse proxy + SSO/auth (Authelia, Authentik, Cloudflare Access, or VPN).

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Primary method; images on Docker Hub |
| Proxmox | LXC (community script) | One-liner install via community-scripts |
| Unraid | Docker Compose (Compose Manager) | Paste compose YAML into Compose Manager |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `PLEXGUARD_FRONTEND_PORT` | Web UI port | `3000` |
| `VERSION` | Docker image version tag | `latest` |

### Phase: Application Setup (via web UI after deploy)
| Setting | Description |
|---------|-------------|
| Plex Server IP | IP/hostname of your Plex server |
| Plex Server Port | Default `32400` |
| Plex Auth Token | Required for API access — [how to find](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) |
| Use SSL/HTTPS | Enable if Plex is on HTTPS |
| Block New Devices | Auto-block all new devices until approved (default: enabled) |
| Session Refresh Interval | How often Guardian polls Plex (seconds; default: 10) |

---

## Software-Layer Concerns

### Config & Environment
- Minimal environment variables — most configuration done through the web UI after deployment
- Create `.env` file alongside `docker-compose.yml` for port/version overrides

### `.env` Example
```bash
PLEXGUARD_FRONTEND_PORT=3000
VERSION=latest
```

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/app/data` | SQLite database + application data |

### Docker Compose (quick start)
```bash
mkdir guardian && cd guardian
curl -o docker-compose.yml https://raw.githubusercontent.com/HydroshieldMKII/Guardian/main/docker-compose.example.yml
curl -o .env https://raw.githubusercontent.com/HydroshieldMKII/Guardian/main/.env.example
docker compose up -d
```

### Access
- Local: `http://localhost:3000`
- Remote: `http://YOUR-SERVER-IP:3000`

### Proxmox LXC
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/guardian.sh)"
```
Access at `http://[CONTAINER-IP]:3000`

### Notification Integrations
- **SMTP**: configure host, port, TLS, sender/recipient in web UI Settings
- **Apprise**: supports 100+ services (Discord, Slack, Telegram, Pushover, etc.) — enter Apprise URL in Settings

---

## Upgrade Procedure

1. **Backup first**: Settings → Admin Tools → Export Database
2. Pull latest images: `docker compose pull`
3. Recreate: `docker compose up -d`
4. Proxmox: `bash -c "$(curl -fsSL .../guardian.sh)" -u` or run `update` inside LXC

---

## Gotchas

- **Do not expose to public internet** without additional auth layer (Authelia, Authentik, Cloudflare Access, or VPN-only access)
- **Plex token** is required, not username/password — find it via Plex web UI or XML API
- **Block New Devices is on by default** — new family/friend devices will be blocked until you approve them in the dashboard
- **Concurrent stream limit**: set Plex itself to "unlimited" streams or Guardian's limit will conflict with Plex's own enforcement
- **Strict Mode** affects existing pending devices retroactively when toggled — review pending device list before enabling
- **Database export before upgrades** is strongly recommended as the project has no dedicated migration guarantees in maintenance mode
- **Watchtower compatible** for automated image updates

---

## Links
- GitHub: https://github.com/HydroshieldMKII/Guardian
- Docker Hub: https://hub.docker.com/r/hydroshieldmkii/guardian-frontend
- Proxmox community script docs: https://community-scripts.github.io/ProxmoxVE/scripts?id=guardian
