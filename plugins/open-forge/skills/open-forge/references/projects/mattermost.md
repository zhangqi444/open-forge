---
name: mattermost-project
description: Mattermost recipe for open-forge. Open-source self-hosted collaboration platform (chat, workflow automation, voice/screen share). Covers Docker Compose deployment with PostgreSQL and NGINX, environment configuration, and upgrade procedure. Derived from https://github.com/mattermost/docker and https://docs.mattermost.com/deployment-guide/server/deploy-containers.html.
---

# Mattermost

Open-source self-hosted collaboration platform: messaging, channels, workflow automation, voice/screen share, and AI integration. Upstream: <https://github.com/mattermost/mattermost>. Docker deploy: <https://github.com/mattermost/docker>. Documentation: <https://docs.mattermost.com/>. License: MIT (core) / Enterprise Edition (paid features).

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.mattermost.com/deployment-guide/server/deploy-containers.html> | yes | Recommended production method. PostgreSQL + NGINX included. |
| Ubuntu package | <https://docs.mattermost.com/deployment-guide/server/deploy-ubuntu.html> | yes | Bare-metal Ubuntu install. |
| Kubernetes (Helm) | <https://docs.mattermost.com/deployment-guide/server/deploy-kubernetes.html> | yes | High-availability cluster. |
| Mattermost Cloud | <https://mattermost.com/sign-up/> | yes (managed) | Hosted service. Out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What domain will Mattermost be hosted at?" | FQDN e.g. mattermost.example.com | Required for SITE_URL and TLS. |
| preflight | "HTTPS port?" | Integer default 443 | HTTPS_PORT in .env. |
| preflight | "HTTP port?" | Integer default 80 | HTTP_PORT in .env. Redirects to HTTPS. |
| config | "PostgreSQL password?" | String sensitive | POSTGRES_PASSWORD in .env. |
| config | "Mattermost edition?" | options: team / enterprise | mattermost-team-edition (free) or mattermost-enterprise-edition (licensed). |
| config | "Timezone?" | TZ string e.g. UTC | TZ in .env. |
| tls | "TLS certificate and key paths?" | host paths | CERT_PATH and KEY_PATH in .env. Or use Let's Encrypt. |

## Docker Compose install

Upstream: <https://github.com/mattermost/docker>

```bash
git clone https://github.com/mattermost/docker
cd docker
cp env.example .env
# Edit .env with your domain, passwords, and paths
mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
sudo chown -R 2000:2000 ./volumes/app/mattermost
docker compose -f docker-compose.yml -f docker-compose.nginx.yml up -d
```

### Key .env variables

```bash
# Required
DOMAIN=mattermost.example.com
TZ=UTC
RESTART_POLICY=unless-stopped

# PostgreSQL
POSTGRES_IMAGE_TAG=18-alpine
POSTGRES_DATA_PATH=./volumes/db/var/lib/postgresql/data
POSTGRES_USER=mmuser
POSTGRES_PASSWORD=mmuser_password
POSTGRES_DB=mattermost

# Mattermost
MATTERMOST_IMAGE=mattermost-team-edition
MATTERMOST_IMAGE_TAG=10
MATTERMOST_CONFIG_PATH=./volumes/app/mattermost/config
MATTERMOST_DATA_PATH=./volumes/app/mattermost/data
MATTERMOST_LOGS_PATH=./volumes/app/mattermost/logs
MATTERMOST_PLUGINS_PATH=./volumes/app/mattermost/plugins
MATTERMOST_CLIENT_PLUGINS_PATH=./volumes/app/mattermost/client/plugins
MATTERMOST_BLEVE_INDEXES_PATH=./volumes/app/mattermost/bleve-indexes
MM_BLEVESETTINGS_INDEXDIR=/mattermost/bleve-indexes
MM_SQLSETTINGS_DRIVERNAME=postgres
MM_SQLSETTINGS_DATASOURCE=postgres://mmuser:mmuser_password@postgres:5432/mattermost?sslmode=disable&connect_timeout=10&binary_parameters=yes
MM_SERVICESETTINGS_SITEURL=https://mattermost.example.com

# NGINX / TLS
NGINX_IMAGE_TAG=alpine
NGINX_CONFIG_PATH=./nginx/conf.d
HTTPS_PORT=443
HTTP_PORT=80
CALLS_PORT=8443
CERT_PATH=./volumes/web/cert/cert.pem
KEY_PATH=./volumes/web/cert/key-no-password.pem
```

### Ports

| Port | Use |
|---|---|
| 80 | HTTP (redirects to HTTPS) |
| 443 | HTTPS Web UI, API, and WebSocket |
| 8443 | Mattermost Calls (voice/video) |

## Software-layer concerns

### Data directories (host)

| Path | Contents |
|---|---|
| ./volumes/app/mattermost/config | config.json and custom configuration |
| ./volumes/app/mattermost/data | User uploads, attachments, emojis |
| ./volumes/app/mattermost/logs | Application logs |
| ./volumes/app/mattermost/plugins | Server-side plugins |
| ./volumes/app/mattermost/client/plugins | Client-side plugins |
| ./volumes/app/mattermost/bleve-indexes | Full-text search indexes |
| ./volumes/db | PostgreSQL data |

### File permissions

Mattermost container runs as uid/gid 2000. Set ownership before first run:
```bash
sudo chown -R 2000:2000 ./volumes/app/mattermost
```

## Upgrade procedure

```bash
# Pull new images
docker compose pull
docker compose up -d
```

Check release notes at <https://docs.mattermost.com/about/mattermost-server-releases.html> before upgrading across major versions. A new compiled release ships on the 16th of each month.

## Gotchas

- **MM_SERVICESETTINGS_SITEURL must match public URL**: Mattermost uses this for absolute URL generation. Wrong value breaks email links, OAuth redirects, and mobile app connections.
- **UID 2000 ownership**: The mattermost container runs as uid 2000. Directories must be owned by 2000:2000 before first start; otherwise the server won't write config or data.
- **PostgreSQL superuser**: The default .env creates a PostgreSQL superuser for mmuser. For hardened deployments, follow the non-superuser guide in docs/creation-of-nonsuperuser.md.
- **Calls port**: Mattermost Calls (voice/video) uses port 8443 (UDP+TCP). Open this port in your firewall if Calls is needed.
- **Bleve vs Elasticsearch**: Bleve is the default full-text search (included). Elasticsearch is supported as an alternative for large deployments (Enterprise feature).
- **Edition**: Use mattermost-team-edition for the free MIT-licensed version. mattermost-enterprise-edition unlocks paid features but requires a license key.

## Links

- GitHub (server): <https://github.com/mattermost/mattermost>
- GitHub (Docker): <https://github.com/mattermost/docker>
- Deployment docs: <https://docs.mattermost.com/deployment-guide/server/deploy-containers.html>
- Release schedule: <https://docs.mattermost.com/about/mattermost-server-releases.html>
