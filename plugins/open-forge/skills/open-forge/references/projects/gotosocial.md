# GoToSocial

**What it is:** Self-hosted ActivityPub social network server written in Go. A lightweight, privacy-respecting Fediverse server compatible with Mastodon clients and the wider ActivityPub ecosystem. Post text, images, and articles; follow others; control post visibility granularly; run single-user or multi-user instances.

**Docs:** https://docs.gotosocial.org  
**Source:** https://codeberg.org/superseriousbusiness/gotosocial  
**Docker image:** `docker.io/superseriousbusiness/gotosocial:latest`

> ⚠️ **Beta software** — deployable and usable; federates with many Fediverse servers; not all features complete. Expected to exit beta ~2026.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose + SQLite | Recommended for most users |
| Any Linux VPS/VM | Docker Compose + PostgreSQL | For larger instances |
| Any Linux | Binary | Pre-built binaries on Codeberg releases |

---

## Inputs to Collect

### Phase: Deploy (required)

| Variable | Description |
|----------|-------------|
| `GTS_HOST` | Domain name of your instance (e.g. `social.example.com`) — **must be set correctly before first run; cannot be changed after** |
| `GTS_DB_TYPE` | Database type: `sqlite` (default) or `postgres` |
| `GTS_DB_ADDRESS` | SQLite: path to db file (e.g. `/gotosocial/storage/sqlite.db`); PostgreSQL: hostname |

### Phase: Optional

| Variable | Description |
|----------|-------------|
| `GTS_LETSENCRYPT_ENABLED` | `true` to use built-in Let's Encrypt (set `false` behind a reverse proxy) |
| `GTS_LETSENCRYPT_EMAIL_ADDRESS` | Email for Let's Encrypt notices |
| `GTS_TRUSTED_PROXIES` | CIDR of trusted reverse proxy (e.g. `172.18.0.1/16`) |
| `TZ` | Timezone |
| `GTS_WAZERO_COMPILATION_CACHE` | Path for Wazero cache (speeds up restarts) |

---

## Software-Layer Concerns

- **`GTS_HOST` cannot be changed after first run** — the domain is baked into ActivityPub actor IDs; changing it breaks federation
- **Data volume** at `~/gotosocial/data:/gotosocial/storage` — contains SQLite DB and all media; back up regularly
- **Run as non-root user** — `user: 1000:1000` in compose; ensure the storage directory is owned by that UID
- **Reverse proxy setup** — recommended for production; set `GTS_LETSENCRYPT_ENABLED: "false"` and expose `127.0.0.1:8080:8080`; configure Nginx/Caddy to terminate TLS
- **Mastodon API compatibility** — works with most Mastodon-compatible clients (Tusky, Ivory, Elk, etc.)
- **OIDC integration** — supported for external auth providers

### Feature highlights

| Feature | Notes |
|---------|-------|
| Granular post visibility | Public, unlisted, followers-only, direct |
| Reply controls | Control who can reply to your posts |
| Local-only posting | Posts that don't federate beyond your instance |
| RSS feeds | Per-account RSS feeds |
| Rich text | Markdown formatting in posts |
| Status pages | (via external tools) |
| Various federation modes | Allowlist, blocklist, etc. |

---

## Example Docker Compose

```yaml
services:
  gotosocial:
    image: docker.io/superseriousbusiness/gotosocial:latest
    container_name: gotosocial
    user: 1000:1000
    environment:
      GTS_HOST: social.example.com
      GTS_DB_TYPE: sqlite
      GTS_DB_ADDRESS: /gotosocial/storage/sqlite.db
      GTS_LETSENCRYPT_ENABLED: "false"
      GTS_TRUSTED_PROXIES: "172.18.0.1/16"
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - ~/gotosocial/data:/gotosocial/storage
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Migrations run automatically on startup
4. Always back up data volume before upgrading (beta software)

---

## Gotchas

- **`GTS_HOST` is permanent** — set it to your final domain before first run; migration to a new domain is not supported
- **Storage directory permissions** — must be owned by the user specified in `user:` (default `1000:1000`)
- **Beta software** — some features not yet implemented; federation may not work with all servers
- **Not a drop-in Mastodon replacement** — missing some Mastodon features (groups, lists, some admin tools); check docs for current feature status
- Port `443:8080` mapping in the example is for standalone (Let's Encrypt) mode; use `127.0.0.1:8080:8080` behind a reverse proxy

---

## Links

- Docs: https://docs.gotosocial.org
- Source (Codeberg): https://codeberg.org/superseriousbusiness/gotosocial
- Installation guide: https://docs.gotosocial.org/en/latest/getting_started/installation/container/
- API docs: https://docs.gotosocial.org/en/latest/api/swagger/
