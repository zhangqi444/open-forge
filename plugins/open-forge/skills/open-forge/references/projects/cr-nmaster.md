---
name: cr-nmaster
description: Recipe for Cr*nMaster — a web-based cron job management UI with live logging, system stats, and OIDC SSO. Docker-only. Based on upstream README at https://github.com/fccview/cronmaster and env-var reference at howto/ENV_VARIABLES.md.
---

# Cr*nMaster

Web-based cron job management interface for Linux systems. View, create, and delete cron jobs with human-readable syntax, optional per-job execution logging with live streaming (SSE), system info (CPU/RAM/network/uptime), script management, REST API, and OIDC SSO support. Runs as a privileged Docker container that directly accesses the host's crontab files. Official project: <https://github.com/fccview/cronmaster>.

Note on the name: the project stylises itself as `cr*nmaster` in text but uses `cronmaster` for the container image and repo slug. This recipe uses the selfh.st slug `cr-nmaster`.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux host (bare metal or VM) | Docker (privileged) | Only supported runtime — requires `pid: host` + `privileged: true` to access host crontab |
| ARM64 host | Docker | Supported; uncomment `platform: linux/arm64` in compose file |

**Windows / macOS**: Not supported — the container manages Linux crontab files directly on the host.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which users' crontabs should CronMaster manage?" | Comma-separated list; defaults to `root`. Set via `HOST_CRONTAB_USER` |
| auth | "Authentication method — password only, OIDC only, or both?" | `AUTH_PASSWORD` sets password auth; `SSO_MODE=oidc` enables OIDC |
| auth | "Password for CronMaster?" | Required unless using OIDC-only (`OIDC_AUTO_REDIRECT=true` + no `AUTH_PASSWORD`) |
| auth (OIDC) | "OIDC issuer URL, client ID, client secret?" | From your identity provider (Authentik, Keycloak, Auth0, etc.) |
| network | "What port should CronMaster listen on?" | Default `40123`; maps to container port `3000` |
| network | "Public URL for CronMaster?" | Required when OIDC is enabled (`APP_URL`). Also used for OIDC redirect URIs |

## Software-layer concerns

- **Image**: `ghcr.io/fccview/cronmaster:latest` (GitHub Container Registry). Multi-arch: amd64 + arm64.
- **Config**: all via environment variables — no config file. Reference: `howto/ENV_VARIABLES.md` in the repo.
- **Data directories** (mount as volumes):
  - `./scripts:/app/scripts` — bash scripts managed through the UI
  - `./data:/app/data` — job execution logs, translations, application state
  - `./snippets:/app/snippets` — reusable script snippets
- **Host crontab access**: the container uses `pid: host` + `privileged: true` + mounts `/var/run/docker.sock` to read/write crontab files on the host directly. This bypasses the `crontab` command limitations in containers.
- **Logging**: execution logs stored under `./data/`. Controlled by `MAX_LOG_AGE_DAYS` (default 30), `MAX_LOGS_PER_JOB` (default 50).
- **ARM64**: uncomment `platform: linux/arm64` in `docker-compose.yml` for ARM64 hosts.

## Docker Compose

Minimal configuration (password auth, manages `root`'s crontab):

```yaml
services:
  cronmaster:
    image: ghcr.io/fccview/cronmaster:latest
    container_name: cronmaster
    user: "root"
    ports:
      - "40123:3000"
    environment:
      - NODE_ENV=production
      - DOCKER=true
      - NEXT_PUBLIC_CLOCK_UPDATE_INTERVAL=30000
      - AUTH_PASSWORD=change_me_strong_password
      - HOST_CRONTAB_USER=root
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./scripts:/app/scripts
      - ./data:/app/data
      - ./snippets:/app/snippets
    pid: "host"
    privileged: true
    restart: always
    init: true
```

Start:

```bash
docker compose up -d
# Open http://<host>:40123
```

### With OIDC SSO

Add to the `environment` block (in addition to or instead of `AUTH_PASSWORD`):

```yaml
- APP_URL=https://cron.yourdomain.com
- SSO_MODE=oidc
- OIDC_ISSUER=https://auth.yourdomain.com
- OIDC_CLIENT_ID=cronmaster
- OIDC_CLIENT_SECRET=<client-secret>
# Optional: auto-redirect to OIDC when no password is set
- OIDC_AUTO_REDIRECT=false
```

The OIDC redirect URI to register with your provider: `${APP_URL}/api/auth/callback/oidc`.

### Managing multiple users' crontabs

```yaml
- HOST_CRONTAB_USER=root,deploy,www-data
```

## Key environment variables

| Variable | Default | Description |
|---|---|---|
| `AUTH_PASSWORD` | — | Login password (leave unset + use OIDC-only if desired) |
| `HOST_CRONTAB_USER` | `root` | Comma-separated crontab users to manage |
| `APP_URL` | Auto | Public URL — required for OIDC |
| `SSO_MODE` | — | Set to `oidc` to enable OIDC SSO |
| `OIDC_ISSUER` | — | OIDC provider issuer URL |
| `OIDC_CLIENT_ID` | — | OIDC client ID |
| `OIDC_CLIENT_SECRET` | — | OIDC client secret |
| `OIDC_AUTO_REDIRECT` | `false` | Auto-redirect to OIDC when no password is set |
| `API_KEY` | — | API key for REST API external access |
| `MAX_LOG_AGE_DAYS` | `30` | Days to retain execution logs |
| `MAX_LOGS_PER_JOB` | `50` | Max log files per job |
| `DISABLE_SYSTEM_STATS` | `false` | Hide system stats sidebar |
| `LOCALE` | `en` | UI language |
| `NEXT_PUBLIC_CLOCK_UPDATE_INTERVAL` | `30000` | Clock refresh interval (ms) |

Full reference: `howto/ENV_VARIABLES.md` in the upstream repo.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the GitHub releases page before upgrading across major versions.

## Gotchas

- **Privileged container with host PID namespace.** CronMaster runs as root with `privileged: true` and `pid: host` to directly read/write host crontab files. Deploy behind a reverse proxy and restrict network access accordingly — do not expose port 40123 directly to the internet.
- **`user: "root"` is required.** The container must run as root to access `/etc/crontab` and per-user crontabs.
- **`/var/run/docker.sock` mount.** The Docker socket is mounted to allow CronMaster to display Docker-related system information. Standard security caveat: anything with the Docker socket can escalate to root on the host.
- **No TLS built-in.** Deploy behind a reverse proxy (Traefik, Caddy, nginx) for TLS termination.
- **ARM64**: uncomment `platform: linux/arm64` in the compose file. AMD64 users need no changes.
- **OIDC requires `APP_URL`.** When `SSO_MODE=oidc`, `APP_URL` must be set to the public URL — the OIDC callback URL is constructed from it.

## References

- Upstream README: https://github.com/fccview/cronmaster
- Environment variables: https://github.com/fccview/cronmaster/blob/main/howto/ENV_VARIABLES.md
- Docker setup guide: https://github.com/fccview/cronmaster/blob/main/howto/DOCKER.md
- SSO guide: https://github.com/fccview/cronmaster/blob/main/howto/SSO.md
- API docs: https://github.com/fccview/cronmaster/blob/main/howto/API.md
