# bit

**Fast, lightweight self-hosted URL shortener** — Crystal-based URL shortener with minimal tracking (country, browser, OS, referer — no cookies), multi-user API key auth, 11k req/sec throughput, sub-20 MiB image, and SQLite storage. Feature-complete by design.

**Official site:** https://github.com/sjdonado/bit
**Source:** https://github.com/sjdonado/bit
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Recommended |
| Any VPS / bare metal | Docker | Single container with SQLite |
| Dokku | Dockerfile | Dokku deployment supported |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / public URL for short links
- Admin name for the initial user

### Phase 2 — Deploy
- `APP_URL` — full public URL (e.g. `https://bit.example.com`)
- `ADMIN_NAME` — name for the admin user
- `ADMIN_API_KEY` — generate with `openssl rand -base64 32`
- `DATABASE_URL` — SQLite path (e.g. `sqlite3://./sqlite/data.db`)

---

## Software-Layer Concerns

- **Stack:** Crystal (compiled binary), SQLite
- **No cookies / no persistent tracking** — only request metadata (country, browser, OS, referer) logged
- **Multi-user:** API key authentication; create/list/delete keys via CLI
- **Auto-updates:** UA regexes and GeoLite2 database update automatically
- **Performance:** 11k req/sec, ~11ms latency, 40 MiB avg memory (benchmarked at 100k requests/125 connections)
- **Feature-complete:** Bug fixes will continue but no new features planned

---

## Deployment

```bash
# Docker single container
docker run \
  --name bit \
  -p 4000:4000 \
  -e ENV="production" \
  -e DATABASE_URL="sqlite3://./sqlite/data.db" \
  -e APP_URL="https://bit.example.com" \
  -e ADMIN_NAME="Admin" \
  -e ADMIN_API_KEY=$(openssl rand -base64 32) \
  -v ./sqlite:/usr/src/app/sqlite \
  sjdonado/bit

# Create additional users
docker exec -it bit cli --create-user=Username
```

```bash
# Docker Compose
git clone https://github.com/sjdonado/bit
cd bit
cp .env.example .env   # edit APP_URL, ADMIN_NAME, ADMIN_API_KEY
docker-compose up -d
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **SQLite volume must be persisted** — mount `./sqlite` as a volume; losing it means losing all short links and analytics
- **`APP_URL` must be set correctly** — used in generated short links; wrong URL breaks all redirects
- **No web UI for user management** — users are managed via the `cli` command inside the container
- **GeoLite2 auto-update** — requires outbound network access to download MaxMind GeoLite2 DB; ensure the container can reach the internet

---

## Links

- Upstream README: https://github.com/sjdonado/bit#readme
- Setup docs: https://github.com/sjdonado/bit/blob/main/docs/SETUP.md
- Docker Hub: https://hub.docker.com/r/sjdonado/bit
