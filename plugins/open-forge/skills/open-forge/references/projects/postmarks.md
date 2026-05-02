# Postmarks

**What it is:** Single-user self-hosted bookmarking site with ActivityPub/Fediverse integration. Save, organize, and share bookmarks from your own domain. Connects to the Fediverse (Mastodon, Firefish, other ActivityPub platforms) so others can interact with your bookmarks. Includes a browser bookmarklet, admin interface, and import support.

**Homepage:** https://postmarks.glitch.me  
**GitHub:** https://github.com/ckolderup/postmarks  
**License:** See repo

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Builds from source; single container |
| Any Linux | Node.js | `npm run start` |
| PaaS (Glitch, Railway, etc.) | Node.js | Designed for easy PaaS deployment |

---

## Inputs to Collect

### Phase: Deploy (`.env` file)

| Variable | Description |
|----------|-------------|
| `PUBLIC_BASE_URL` | Hostname of your instance (e.g. `bookmarks.example.com`) — required for ActivityPub federation |
| `ADMIN_KEY` | Password for the admin interface — set this before first run |
| `SESSION_SECRET` | Random string for secure session cookie hashing |
| `PORT` | Listen port (default `3000`) |

### Phase: Optional

| Variable | Description |
|----------|-------------|
| `MASTODON_ACCOUNT` | Your Mastodon handle — enables Mastodon verification link on homepage |

### `account.json` (required)

Copy `account.json.example` to `account.json` and edit:

| Field | Description |
|-------|-------------|
| `username` | Your Fediverse actor name (default `bookmarks` → `@bookmarks@yourhostname`) |
| display name | Name shown on your profile |
| bio | Short bio |
| avatar | Absolute URL to your avatar image |

---

## Software-Layer Concerns

- **Flat-file / SQLite storage** in `.data/` directory — mount `./data:/app/.data` to persist
- **`account.json`** defines your ActivityPub actor; mount as read-only: `./account.json:/app/account.json:ro`
- **Single-user** — one admin account, one Fediverse actor per instance
- **Default port binding** in Docker Compose is `127.0.0.1:3000:3000` — designed to run behind a reverse proxy, not exposed directly to the internet
- **Bookmarklet** available in the Admin section for one-click saving from any browser

---

## Example Docker Compose

```yaml
services:
  postmarks:
    build: .
    env_file: .env
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - ./.data:/app/.data
      - ./account.json:/app/account.json:ro
```

---

## Upgrade Procedure

1. Pull latest source: `git pull`
2. Rebuild image: `docker compose build`
3. Restart: `docker compose up -d`
4. Data persists in `.data/` volume

---

## Gotchas

- **`PUBLIC_BASE_URL` must match your actual hostname** — ActivityPub federation uses this as the actor ID; changing it after federation is established will break existing connections
- **`ADMIN_KEY` and `SESSION_SECRET` must be set** before first run; leaving them empty disables admin access or uses insecure defaults
- **Docker Compose builds from source** (no pre-built image) — first build takes longer
- Default Docker binding is `127.0.0.1:3000` — requires a reverse proxy (Caddy, Nginx) to be accessible from outside
- Avatar URL in `account.json` must be an absolute URL — the repo includes a default static image

---

## Links

- Homepage: https://postmarks.glitch.me
- GitHub: https://github.com/ckolderup/postmarks
- Getting Started: https://casey.kolderup.org/notes/b059694f5064c6c6285075c894a72317.html
