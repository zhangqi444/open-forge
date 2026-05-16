---
name: zealot
description: "Self-hosted mobile app distribution platform. MIT. tryzealot. Docker Compose + PostgreSQL. Multi-platform app hosting (iOS, Android, macOS, Linux, Windows), fastlane integration, SDK support, SSO via OAuth2/LDAP/OIDC, automatic iOS test device registration, WebHook notifications, beta testing workflows. Open-source alternative to TestFlight / Firebase App Distribution."
---

# Zealot

**Self-hosted continuous everything platform for app distribution.** Upload, manage, and distribute iOS, Android (APK/AAB), macOS, Windows, and Linux apps to beta testers — with CI/CD integration, fastlane plugins, and automatic iOS test device syncing. MIT license.

Built + maintained by **tryzealot** (community project).

- Upstream repo: <https://github.com/tryzealot/zealot>
- Deploy repo: <https://github.com/tryzealot/zealot-docker>
- Docs: <https://zealot.ews.im/docs/self-hosted>
- Demo: <https://tryzealot.ews.im> (admin@zealot.com / ze@l0t)

## Architecture in one minute

- Ruby on Rails application backed by **PostgreSQL** (required) and optionally **Redis** (for background jobs via Sidekiq)
- Official Docker image: `ghcr.io/tryzealot/zealot:6.2.1`
- Deploy via the `zealot-docker` helper repo which generates a full `docker-compose.yml` from a `.env` template with Caddy as a reverse proxy for automatic TLS

## Compatible install methods

| Method | Notes |
|--------|-------|
| **Docker Compose via deploy script** | **Primary** — clone `zealot-docker`, configure `.env`, run `./deploy` |
| Kubernetes | Helm chart documented at upstream |
| Nomad | Nomad job spec documented at upstream |
| Source | Rails app — for contributors only |

## Inputs to collect

| Input | Example | Phase | Notes |
|-------|---------|-------|-------|
| Domain | `zealot.example.com` | DNS | Must be publicly reachable for iOS app installs |
| TLS mode | Let's Encrypt / self-signed / no SSL | TLS | Self-signed requires manual cert install on every iOS device |
| Admin email | `admin@example.com` | Account | Default login |
| Admin password | — | Account | Replace default `ze@l0t` |
| Secret key | `openssl rand -hex 64` | Security | Required: `SECRET_KEY_BASE` |
| SMTP host/creds | — | Email | Optional for notifications |

## Install via Docker Compose (zealot-docker)

### Step 1 — Clone the deploy repo

```bash
git clone https://github.com/tryzealot/zealot-docker.git
cd zealot-docker
```

### Step 2 — Configure `.env`

```bash
cp config.env .env
```

Edit `.env` — minimum required settings:

```dotenv
# Domain (no http:// prefix)
ZEALOT_DOMAIN=zealot.example.com

# TLS mode — pick one:
ZEALOT_CERT_EMAIL=you@example.com   # Let's Encrypt (recommended)
# ZEALOT_CERT=cert.pem              # Self-signed cert path (conflicts with ZEALOT_CERT_EMAIL)

# Admin account
ZEALOT_ADMIN_EMAIL=admin@zealot.com
ZEALOT_ADMIN_PASSWORD=ze@l0t        # Change this!

# Secret key — generate with: openssl rand -hex 64
SECRET_KEY_BASE=

# Database
ZEALOT_POSTGRES_HOST=postgres
ZEALOT_POSTGRES_PORT=5432
ZEALOT_POSTGRES_USERNAME=postgres
ZEALOT_POSTGRES_PASSWORD=ze@l0t
ZEALOT_POSTGRES_DB_NAME=zealot
```

Optional SMTP (for email notifications):

```dotenv
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=you@example.com
SMTP_PASSWORD=your_password
SMTP_AUTH_METHOD=plain
SMTP_ENABLE_STARTTLS=true
ACTION_MAILER_DEFAULT_FROM=notifications@zealot.example.com
```

### Step 3 — Run the deploy script

```bash
./deploy
```

The script interactively generates `docker-compose.yml` (with Caddy for TLS) and starts the stack. To manually start after generation:

```bash
docker compose up -d
```

### Step 4 — First login

Navigate to `https://zealot.example.com` and log in with the admin credentials from `.env`.

## Docker Compose base structure

The generated Compose file includes at minimum:

```yaml
services:
  postgres:
    image: postgres:14-alpine
    volumes:
      - zealot-postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ze@l0t
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
    restart: unless-stopped

  zealot:
    image: ghcr.io/tryzealot/zealot:6.2.1
    depends_on:
      - postgres
    env_file: .env
    volumes:
      - zealot-uploads:/app/public/uploads
      - zealot-backup:/app/public/backup
      - ./log:/app/log
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider --proxy=off 127.0.0.1/api/health || exit 1"]
    restart: unless-stopped
```

> Caddy is added by the deploy script on top. The Zealot container listens on port `80` internally.

## Key features

- **Multi-platform app hosting**: iOS (`.ipa`), Android (`.apk`/`.aab`), macOS, Linux, Windows
- **CI/CD integrations**: fastlane plugin (`fastlane-plugin-zealot`), REST API, iOS SDK, Android SDK
- **iOS device management**: Automatically syncs test device UDIDs to Apple Developer; one-click device registration
- **App metadata parsing**: Reads metadata from iOS provisioning profiles and Android manifests
- **SSO**: Feishu, GitLab, GitHub, Google, LDAP, OIDC
- **WebHook notifications**: Custom event payloads to any webhook endpoint
- **Channel management**: Organize apps by channel (e.g., staging vs. production, by product line)
- **Guest mode**: Optional unauthenticated browsing

## Reverse proxy

The `deploy` script configures **Caddy** for automatic TLS. For self-managed Nginx/Traefik, see the [reverse proxies doc](https://zealot.ews.im/docs/self-hosted/reverse-proxies).

## Updating

```bash
docker compose pull
docker compose up -d
```

## Backup & restore

```bash
# Create backup
docker compose exec zealot /app/bin/backup

# Backup archives land in the zealot-backup volume (./backup/ on the host by default)
```
