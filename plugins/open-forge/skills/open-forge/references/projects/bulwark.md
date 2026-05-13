# Bulwark Webmail

A modern, self-hosted webmail client for Stalwart Mail Server, built with Next.js and the JMAP protocol. Provides a full suite in one login: Mail (threading, full-text search, Sieve filters, S/MIME), Calendar (drag-to-reschedule, iMIP, CalDAV), Contacts (address books, vCard import/export), and Files (JMAP FileNode storage). Extras: OAuth2/OIDC SSO, TOTP 2FA, multi-account (up to 5), 15 languages, PWA, dark/light themes, plugin marketplace, and an admin dashboard.

- **GitHub:** https://github.com/bulwarkmail/webmail
- **Docker image:** `ghcr.io/bulwarkmail/webmail:latest`
- **License:** AGPL-3.0
- **Requires:** A JMAP-compatible mail server — primarily designed for [Stalwart Mail Server](https://stalw.art/)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container + 3 named volumes; JMAP server required separately |
| Any Docker host | docker run | One-liner for quick testing |

---

## Inputs to Collect

### Deploy Phase (.env.local)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| JMAP_SERVER_URL | Yes | — | URL of your JMAP mail server (e.g. https://mail.example.com) |
| APP_NAME | No | Bulwark Webmail | UI title / PWA manifest name |
| SESSION_SECRET | No* | — | Required for "Remember me" and settings sync; generate with: openssl rand -base64 32 |
| STALWART_FEATURES | No | true | Set false if using a non-Stalwart JMAP server |
| ALLOW_CUSTOM_JMAP_ENDPOINT | No | — | Set true to show a JMAP server field on login (multi-server) |
| HOSTNAME | No | 0.0.0.0 | Bind address; use :: for dual-stack IPv6 |
| PORT | No | 3000 | Listen port |
| LOG_FORMAT | No | text | text or json |
| BULWARK_TELEMETRY | No | on | Set off to disable anonymous telemetry |
| SETTINGS_SYNC_ENABLED | No | — | Set true to enable server-side settings sync (requires SESSION_SECRET) |

### OAuth2/OIDC (optional)
| Variable | Description |
|----------|-------------|
| OAUTH_ENABLED | Set true to enable OAuth login |
| OAUTH_ONLY | Set true to hide username/password form (OIDC only) |
| OAUTH_CLIENT_ID | OAuth client ID |
| OAUTH_CLIENT_SECRET | OAuth client secret |
| OAUTH_ISSUER_URL | OIDC discovery URL |

Config goes in .env.local (copy from .env.example).

---

## Software-Layer Concerns

### Config
- .env.local — active config (never commit secrets)
- .env.example — full reference with all variables documented

### Data Directories
| Volume | Path in container | Contents |
|--------|------------------|----------|
| bulwark-settings | /app/data/settings | Encrypted per-user settings (settings sync) |
| bulwark-admin | /app/data/admin | Admin config, password hash, plugins, audit logs |
| bulwark-telemetry | /app/data/telemetry | Instance ID and consent state |

### Ports
- 3000 — Web UI (configurable)

---

## Minimal docker-compose.yml

```yaml
services:
  webmail:
    image: ghcr.io/bulwarkmail/webmail:latest
    ports:
      - "3000:3000"
    environment:
      - JMAP_SERVER_URL=https://your-jmap-server.com
    env_file:
      - .env.local
    volumes:
      - bulwark-settings:/app/data/settings
      - bulwark-admin:/app/data/admin
      - bulwark-telemetry:/app/data/telemetry
    restart: unless-stopped

volumes:
  bulwark-settings:
  bulwark-admin:
  bulwark-telemetry:
```

Quick test:
```bash
docker run -d -p 3000:3000 \
  -e JMAP_SERVER_URL=https://mail.example.com \
  ghcr.io/bulwarkmail/webmail:latest
```

---

## Upgrade Procedure

```bash
docker compose pull webmail
docker compose up -d webmail
```

All state is in named volumes; no data migration needed.

---

## Gotchas

- **Stalwart Mail Server is the primary target:** Bulwark is designed specifically for Stalwart's JMAP implementation; most features (Sieve filters, password change, file storage) require Stalwart — set STALWART_FEATURES=false for other JMAP servers
- **JMAP server must exist separately:** Bulwark is a frontend only — you need a running JMAP mail server before deploying Bulwark
- **SESSION_SECRET for "Remember me":** Without it, sessions are not persistent across restarts and settings sync is disabled; generate with: openssl rand -base64 32
- **Setup wizard on first run (v1.6.4+):** If `JMAP_SERVER_URL` is *not* set in the environment, visiting the container root triggers a web-based setup wizard that walks through server, auth, security (SESSION_SECRET), logging, branding, and admin password -- no `.env.local` editing required. Setting `JMAP_SERVER_URL` env var skips the wizard and uses env-managed configuration instead. Admin data (password hash, plugins) is stored in the bulwark-admin volume.
- **CORS for ALLOW_CUSTOM_JMAP_ENDPOINT:** If allowing custom JMAP endpoints, the external JMAP server must include Bulwark's domain in its CORS Access-Control-Allow-Origin header
- **Telemetry is anonymous:** Contains no PII (version, feature toggles, bucketed counts only); disable with BULWARK_TELEMETRY=off if preferred
- **Plugin marketplace:** Third-party plugins install as .zip bundles via the admin dashboard

---

## References
- README: https://github.com/bulwarkmail/webmail
- .env.example: https://raw.githubusercontent.com/bulwarkmail/webmail/HEAD/.env.example
- FEATURES.md: https://github.com/bulwarkmail/webmail/blob/HEAD/FEATURES.md
- Stalwart Mail Server: https://stalw.art/
