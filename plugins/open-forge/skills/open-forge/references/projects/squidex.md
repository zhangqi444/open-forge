---
name: squidex
description: Squidex recipe for open-forge. Covers Docker Compose self-hosted deploy with MongoDB and Caddy TLS proxy. Squidex is an open-source headless CMS built on .NET with CQRS/event-sourcing, a rich REST/GraphQL API, and a schema-driven content editor.
---

# Squidex

Open-source headless CMS built on ASP.NET Core with CQRS and event-sourcing architecture. Provides a schema-driven content API (REST + GraphQL + OData filtering), a visual content editor, workflow rules, multi-language support, and role-based access. Upstream: <https://github.com/Squidex/squidex>. Docs: <https://docs.squidex.io>. Demo: <https://cloud.squidex.io>.

**License:** MIT · **Language:** .NET (C#) · **Default port:** 5000 (proxied via Caddy to 80/443) · **Stars:** ~2,500

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (MongoDB + Caddy) | <https://docs.squidex.io/01-getting-started/installation/platforms/install-docker> | ✅ | **Recommended** — includes MongoDB, Squidex, and Caddy as TLS proxy. |
| Azure | <https://docs.squidex.io/01-getting-started/installation/platforms/install-azure> | ✅ | ARM template deploy to Azure App Service. |
| Kubernetes | <https://docs.squidex.io/01-getting-started/installation/platforms/install-on-kubernetes> | ✅ | Production-scale Helm chart deploy. |
| IIS (Windows) | <https://docs.squidex.io/01-getting-started/installation/platforms/install-iis> | ✅ | Windows Server with IIS. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "What domain will Squidex be served on? (e.g. cms.example.com)" | Free-text | Required — used for TLS cert and URLS__BASEURL. |
| admin_email | "Admin account email address?" | Free-text | Initial admin setup. |
| admin_password | "Admin account password?" | Free-text (sensitive) | Initial admin setup. |
| oauth | "Enable social login? (Google, GitHub, Microsoft OAuth)" | AskUserQuestion: Yes / No | Optional — requires provider credentials. |

## Install — Docker Compose

Reference: <https://docs.squidex.io/01-getting-started/installation/platforms/install-docker>

```bash
mkdir squidex && cd squidex

# Download the official hosting compose file
curl -O https://raw.githubusercontent.com/Squidex/squidex-hosting/master/docker-compose/docker-compose.yml

# Create .env file
cat > .env << 'ENV'
SQUIDEX_DOMAIN=cms.example.com
SQUIDEX_ADMINEMAIL=admin@example.com
SQUIDEX_ADMINPASSWORD=<strong-password>
# Optional OAuth (leave blank to disable)
SQUIDEX_GOOGLECLIENT=
SQUIDEX_GOOGLESECRET=
SQUIDEX_GITHUBCLIENT=
SQUIDEX_GITHUBSECRET=
SQUIDEX_MICROSOFTCLIENT=
SQUIDEX_MICROSOFTSECRET=
ENV

docker compose up -d
```

Squidex will be available at `https://cms.example.com` with a Let's Encrypt TLS certificate (provisioned automatically by Caddy on first request — port 80 must be reachable for ACME challenge).

### Docker Compose services

| Service | Image | Purpose |
|---|---|---|
| `squidex_mongo` | `mongo:6` | MongoDB database (event store + content store) |
| `squidex_squidex` | `squidex/squidex:7` | Headless CMS app (port 5000 internal) |
| `squidex_proxy` | `squidex/caddy-proxy` | Caddy reverse proxy with auto-TLS (ports 80/443) |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | MongoDB 6 — stores content, schemas, events, and assets. Squidex uses a CQRS/event-sourcing architecture; all writes go through the event store. |
| URLS__BASEURL | **Must match your exact public HTTPS URL.** Wrong value breaks OAuth redirects, asset URLs, and the web editor. |
| TLS | Handled by the bundled Caddy proxy which auto-provisions Let's Encrypt certs. Port 80 must be publicly accessible for the ACME HTTP challenge. |
| Assets | File uploads stored in `/app/Assets` inside the squidex container — mount as a volume (already done in the official compose). |
| Caching | Squidex uses in-memory caching by default. For multi-replica deploys, configure Redis as a distributed cache. |
| Auth | Built-in identity provider (email/password). Optional Google, GitHub, and Microsoft OAuth via env vars. |
| API | REST API at `/api/`, GraphQL at `/api/graphql`, Swagger UI at `/api/swagger`. |
| Schemas | Content schemas are defined in the Squidex UI and determine the API shape. Schemas can be versioned and migrated. |

## Upgrade procedure

```bash
# Edit docker-compose.yml to update the squidex image tag, e.g.:
# image: "squidex/squidex:7.23"  →  image: "squidex/squidex:7.24"

docker compose pull
docker compose up -d
```

Squidex applies database migrations automatically on startup. Back up MongoDB before major version upgrades:

```bash
docker compose exec squidex_mongo mongodump --out /data/backup-$(date +%Y%m%d)
```

## Gotchas

- **SQUIDEX_DOMAIN must be exact:** The domain in `.env` is used for URLS__BASEURL and Caddy's TLS provisioning. If it doesn't match the actual hostname, Let's Encrypt will fail and the app will redirect incorrectly.
- **Port 80 required for TLS:** Caddy needs port 80 reachable for ACME HTTP-01 challenge on first run. If port 80 is firewalled, TLS provisioning fails silently and Caddy falls back to HTTP.
- **MongoDB data volume at `/etc/squidex/mongo/db`:** The official compose mounts MongoDB data to a host path (`/etc/squidex/mongo/db`). Ensure this directory exists and is writable before starting: `sudo mkdir -p /etc/squidex/mongo/db`.
- **Assets volume at `/etc/squidex/assets`:** Same — create before first start: `sudo mkdir -p /etc/squidex/assets`.
- **Event sourcing means growing DB:** Squidex never deletes events — the event store grows over time. Plan MongoDB disk capacity accordingly for large/active installations.
- **API authentication:** Content API calls require either a client credentials token (OAuth2 client ID/secret from app settings) or a bearer token from the identity system.

## Upstream links

- GitHub: <https://github.com/Squidex/squidex>
- Hosting repo (Docker Compose): <https://github.com/Squidex/squidex-hosting>
- Documentation: <https://docs.squidex.io>
- Docker install guide: <https://docs.squidex.io/01-getting-started/installation/platforms/install-docker>
- Docker Hub: <https://hub.docker.com/r/squidex/squidex>
- Demo: <https://cloud.squidex.io>
