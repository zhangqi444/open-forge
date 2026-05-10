---
name: midarr
description: Recipe for self-hosting Midarr — a minimal, lightweight Elixir/Phoenix media server that integrates with Radarr and Sonarr to serve your existing media library through a polished web UI with user management and OIDC support.
---

# Midarr

Lightweight companion media server that wraps your existing Radarr + Sonarr library in a sleek web interface with user authentication, real-time online statuses, and an invite system. Unlike Plex/Jellyfin it does not re-index or transcode — it serves media directly from disk via the paths your Radarr/Sonarr already manage. Upstream: <https://github.com/midarrlabs/midarr-server>. Official image: `ghcr.io/midarrlabs/midarr-server`.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Official method. PostgreSQL required (bundled in compose). |
| Any Linux host | Docker standalone | Requires external PostgreSQL. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| app | "What URL will Midarr be accessible at (e.g. `http://midarr.local:4000`)?" | Used for `APP_URL` env var. |
| db | "PostgreSQL username, password, and database name?" | Used for `DB_*` env vars. |
| admin | "Admin account email, display name, and password (min 12 chars)?" | Creates the initial admin user on first start. |
| media | "Path to your media root directory?" | Mount point shared with Radarr/Sonarr. |
| integrations | "Radarr base URL and API key?" | Required for movie library integration. |
| integrations | "Sonarr base URL and API key?" | Required for TV series integration. |
| smtp (optional) | "SMTP credentials (SendGrid API key) for the invite system?" | Optional — needed only to email invites to users. |
| oidc (optional) | "OIDC provider details (client ID, secret, issuer URL)?" | Optional — enables SSO via Authentik, Authelia, etc. |

## Software-layer concerns

### Config paths
All configuration is via environment variables; no config file on disk.

### Key env vars

```
# App
APP_URL=http://midarr:4000

# Database
DB_USERNAME=my_user
DB_PASSWORD=my_password
DB_DATABASE=my_database
DB_HOSTNAME=postgresql

# Admin account (first-run bootstrap)
SETUP_ADMIN_EMAIL=admin@email.com
SETUP_ADMIN_NAME=admin
SETUP_ADMIN_PASSWORD=somepassword    # minimum 12 characters

# Radarr integration
RADARR_BASE_URL=radarr:7878
RADARR_API_KEY=<api-key>

# Sonarr integration
SONARR_BASE_URL=sonarr:8989
SONARR_API_KEY=<api-key>

# Invite emails (optional — requires SendGrid)
APP_MAILER_FROM=example@email.com
SENDGRID_API_KEY=<api-key>

# OIDC / OAuth 2.0 (optional)
OAUTH_CLIENT_ID=someClientId
OAUTH_CLIENT_SECRET=someClientSecret
OAUTH_ISSUER_URL=http://some-provider.url
OAUTH_AUTHORIZE_URL=http://some-provider.url/authorize
OAUTH_TOKEN_URL=http://some-provider.url/token
OAUTH_REDIRECT_URI=http://some-provider.url/auth/callback
OAUTH_USER_URL=http://some-provider.url/user
```

### Docker Compose (from upstream README)

```yaml
volumes:
  database-data:

services:

  midarr:
    container_name: midarr
    image: ghcr.io/midarrlabs/midarr-server:latest
    ports:
      - 4000:4000
    volumes:
      - /path/to/media:/media
    environment:
      - APP_URL=http://midarr:4000
      - DB_USERNAME=my_user
      - DB_PASSWORD=my_password
      - DB_DATABASE=my_database
      - DB_HOSTNAME=postgresql
      - SETUP_ADMIN_EMAIL=admin@email.com
      - SETUP_ADMIN_NAME=admin
      - SETUP_ADMIN_PASSWORD=somepassword
      - RADARR_BASE_URL=radarr:7878
      - RADARR_API_KEY=someApiKey
      - SONARR_BASE_URL=sonarr:8989
      - SONARR_API_KEY=someApiKey
    depends_on:
      postgresql:
        condition: service_healthy

  postgresql:
    container_name: postgresql
    image: postgres
    volumes:
      - database-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=my_user
      - POSTGRES_PASSWORD=my_password
      - POSTGRES_DB=my_database
    healthcheck:
      test: "exit 0"
```

### Ports
- 4000/tcp — Midarr web UI and API

### Media mount alignment
Midarr, Radarr, and Sonarr must share the same media root path so Midarr can resolve files. Mount the same directory in all three containers:

```yaml
# In each service
volumes:
  - /path/to/media:/media
```

### Webhook sync (Radarr/Sonarr → Midarr)
To keep the library in sync add a webhook in Radarr/Sonarr under **Settings → Connect → Webhook**:
- URL: `http://midarr:4000/api/v1/radarr?token=<api-token>` (token found in Midarr Settings)
- Events: On Movie Added, On Movie File Added, On Movie File Deleted

## Upgrade procedure

```bash
docker compose pull midarr
docker compose up -d midarr
```

Check release notes at: <https://github.com/midarrlabs/midarr-server/releases>

## Gotchas

- **Radarr/Sonarr required** — Midarr has no built-in media scanner; it delegates entirely to these integrations. If they're not configured, the library will be empty.
- **Media paths must match** — If Radarr says a file is at `/movies/Dune.mkv`, Midarr must also see it at `/movies/Dune.mkv`. Use identical bind-mount paths across services.
- **Admin bootstrap** — `SETUP_ADMIN_*` vars only take effect on first startup when the database is empty. Remove or keep them after that (they're idempotent).
- **OIDC auth flow** — Navigate to `/auth` (not the normal login page) to initiate an OIDC login.
- **Supported formats** — Direct streaming only; no transcoding. H.264/H.265 video, AAC/MP3 audio, MP4/MKV containers. Anything outside these must be pre-transcoded by other tools.
- **SendGrid only for invites** — The invite email system is hard-coded to SendGrid. Generic SMTP is not supported for invites (only SendGrid API key).

## References
- Upstream README: <https://github.com/midarrlabs/midarr-server#readme>
- Release notes: <https://github.com/midarrlabs/midarr-server/releases>
