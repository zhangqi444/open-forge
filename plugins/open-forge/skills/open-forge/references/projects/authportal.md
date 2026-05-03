# AuthPortal

> Lightweight authentication gateway for Plex, Jellyfin, and Emby — unified login page that authenticates users against your media server and issues signed sessions. Includes OAuth 2.1/OIDC server, RBAC, TOTP MFA, LDAP sync, and a web-based admin console. Single Go binary; PostgreSQL backend.

**Official URL:** https://github.com/modom-ofn/auth-portal  
**Docker Hub:** https://hub.docker.com/r/modomofn/auth-portal

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; includes PostgreSQL |
| Any Linux VPS/VM | Binary (Go) | Build from source |

**Requires:** Plex, Jellyfin, or Emby (at least one as the auth provider)

---

## Inputs to Collect

### Phase: Pre-Deploy (Required)
| Input | Description | Example |
|-------|-------------|---------|
| `POSTGRES_PASSWORD` | PostgreSQL password | strong random string |
| `SESSION_SECRET` | Session signing secret (32+ chars) | `openssl rand -hex 32` |
| `SESSION_COOKIE_DOMAIN` | Cookie domain | `yourdomain.com` |
| `APP_BASE_URL` | Public URL of AuthPortal | `https://auth.example.com` |
| `DATA_KEY` | 32-byte base64 encryption key | `openssl rand -base64 32` |
| `ADMIN_BOOTSTRAP_USERS` | Comma-separated `username:email` pairs for initial admins | `admin:admin@example.com` |
| `MEDIA_SERVER` | Auth provider: `plex`, `jellyfin`, or `emby` | `plex` |

### Phase: Media Server Config (pick one)
**Plex:**
| Input | Description |
|-------|-------------|
| `PLEX_OWNER_TOKEN` | Plex auth token of the server owner |
| `PLEX_SERVER_MACHINE_ID` or `PLEX_SERVER_NAME` | Identify which Plex server to use |

**Jellyfin:**
| Input | Description |
|-------|-------------|
| `JELLYFIN_SERVER_URL` | Jellyfin server URL |
| `JELLYFIN_API_KEY` | Jellyfin API key |

**Emby:**
| Input | Description |
|-------|-------------|
| `EMBY_SERVER_URL` | Emby server URL |
| `EMBY_API_KEY` | Emby API key |
| `EMBY_OWNER_USERNAME` + `EMBY_OWNER_ID` | Emby owner credentials |

### Phase: Optional
| Input | Description | Default |
|-------|-------------|---------|
| `MFA_ENABLE` | Enable TOTP MFA support | `1` |
| `MFA_ENFORCE` | Require MFA for all users | `0` |
| `OIDC_SIGNING_KEY_PATH` | Path to RS256 PEM key for OIDC tokens | `/run/secrets/oidc_signing_key.pem` |
| `OIDC_ISSUER` | OIDC issuer URL | `https://auth.example.com` |
| `FORCE_SECURE_COOKIE` | Set `1` when behind TLS | `0` |
| `LDAP_HOST` | LDAP server for sync (optional) | `ldap://ldap.example.com:389` |

---

## Software-Layer Concerns

### Docker Compose (minimal)
```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: authportaldb
      POSTGRES_USER: authportal
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data

  auth-portal:
    image: modomofn/auth-portal:latest
    ports:
      - "8089:8080"
    env_file: .env
    depends_on:
      - postgres

volumes:
  pgdata:
```

### Ports
- Default: `8089` → maps to container `8080`; proxy with Nginx/Caddy for TLS

### FORCE_SECURE_COOKIE
Set `FORCE_SECURE_COOKIE=1` when running behind a TLS-terminating reverse proxy; otherwise session cookies will not be set with the Secure flag.

### OIDC/OAuth 2.1
AuthPortal exposes standard OIDC discovery (`/.well-known/openid-configuration`), JWKS, token, and userinfo endpoints — use it as an identity provider for downstream apps (Organizr, Heimdall, etc.).

### Admin Console
Accessible at `/admin`; manage providers, RBAC roles/permissions, OAuth clients, LDAP sync, backups, and live log stream.

---

## Upgrade Procedure

1. Pull latest: `docker compose pull`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. Check the release notes for any manual migration steps (especially for major versions)
5. Upgrade guide: https://github.com/modom-ofn/auth-portal#upgrade-guide

---

## Gotchas

- **FORCE_SECURE_COOKIE must be `1` behind TLS** — otherwise the login session cookie won't be set correctly by browsers on HTTPS
- **Use at your own risk** — the project explicitly notes it uses AI-assisted (vibe coding) development; test before relying on it in production
- **Not endorsed by Plex/Jellyfin/Emby** — AuthPortal is an independent project; no official affiliation
- **OIDC signing key** — generate a PEM key before first run: `openssl genrsa -out oidc_signing_key.pem 2048`; mount at `OIDC_SIGNING_KEY_PATH`
- **ADMIN_BOOTSTRAP_USERS** — admin accounts are created from this env var on first startup; the accounts must authenticate via the configured media server

---

## Links
- GitHub: https://github.com/modom-ofn/auth-portal
- Docker Hub: https://hub.docker.com/r/modomofn/auth-portal
