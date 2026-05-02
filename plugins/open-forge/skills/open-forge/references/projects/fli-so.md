# fli.so

**URL shortener with branding, analytics, and QR codes**
Official site: https://github.com/thisuxhq/fli.so

fli.so is a lightning-fast URL shortener built with SvelteKit and PocketBase. Supports custom slugs, link expiry, password protection, QR codes, and meta tag control — all self-hosted with SQLite via PocketBase.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker-compose | Two containers: SvelteKit app + PocketBase |
| VPS / bare metal | docker-compose | Requires reverse proxy for HTTPS |

## Inputs to Collect

### Phase: Pre-deployment
- `PUBLIC_APPLICATION_NAME` — display name for the app
- `PUBLIC_APPLICATION_URL` / `PUBLIC_SITE_URL` — public URL (e.g. `https://short.example.com`)
- `POCKETBASE_ADMIN_EMAIL` — PocketBase superuser email
- `POCKETBASE_ADMIN_PASSWORD` — PocketBase superuser password (choose strong)
- `ENCRYPTION` — arbitrary secret key for link encryption
- `HASH_KEY` — arbitrary secret key for hashing

### Phase: Optional integrations
- `METADATA_SCRAPER_URL` — Cloudflare Workers URL for OG metadata scraping (optional)
- `STRIPE_*` — Stripe keys if you want billing tiers (self-hosted ignores tiers by default)

## Software-Layer Concerns

**Config paths:**
- `./pocketbase/pb_data` — PocketBase database and files (back this up)
- `.env` — loaded by the SvelteKit container via `env_file`

**Key env vars:**
| Variable | Purpose |
|----------|---------|
| `PUBLIC_POCKETBASE_URL` | Internal URL SvelteKit uses to reach PocketBase (use Docker service name) |
| `POCKETBASE_URL` | Same as above (server-side) |
| `ENCRYPTION` | Secret used to encrypt link data |
| `HASH_KEY` | Key for HMAC hashing |
| `PUBLIC_FREE_URL_LIMIT` | Max URLs for free tier (self-hosted: set to 0 for unlimited) |

**Ports:**
- SvelteKit app: `3000`
- PocketBase admin UI: `8090`

**Note:** PocketBase admin UI at `/_/` should be protected behind auth or firewall — do not expose publicly.

## Upgrade Procedure

1. Pull latest images: `docker-compose pull`
2. Recreate containers: `docker-compose up -d`
3. PocketBase data in `./pocketbase/pb_data` persists across upgrades
4. Check release notes for schema migrations before upgrading major versions

## Gotchas

- **Builds from source** — the SvelteKit container builds from the Dockerfile at startup; first run takes longer
- **ORIGIN must match public URL** — set `ORIGIN` in the SvelteKit service env to your public URL to prevent CORS errors
- **No official prebuilt image** — must clone the repo and use `docker-compose` with the included Dockerfile
- **Stripe optional** — self-hosted deployments ignore billing; all features available without Stripe keys
- **PocketBase admin setup** — visit `http://your-host:8090/_/` on first run to initialize the admin account before using the app

## References
- Upstream README: https://github.com/thisuxhq/fli.so/blob/HEAD/README.md
- Docker Compose: https://github.com/thisuxhq/fli.so/blob/HEAD/docker-compose.yml
