# ShotShare

**What it is:** A self-hosted, bare-bones image sharing platform. Upload screenshots, share links with friends — no ads, no bloat. Supports SQLite or MySQL/PostgreSQL, Caddy-powered automatic HTTPS, reactions, UUID routes, and Plex-style direct/markdown/BBCode share links.

**Official URL:** https://github.com/mdshack/shotshare
**Docker Hub:** `mdshack/shotshare`
**Demo:** https://demo.shotshare.dev/
**License:** MIT
**Stack:** PHP (Laravel) + SQLite/MySQL/PostgreSQL + Caddy

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker (HTTPS mode) | Recommended; Caddy handles SSL automatically |
| Any Linux VPS / bare metal | Docker (HTTP mode) | For use behind your own reverse proxy |
| Homelab | Docker | SQLite default is fine for personal use |

---

## Inputs to Collect

### Pre-deployment
- `HOST` — your public domain (e.g. `screenshots.example.com`); Caddy auto-issues SSL
- `ALLOW_REGISTRATION` — `true` (open) or `false` (closed)
- `FEATURE_UUID_ROUTES` — `true` recommended (obfuscates image IDs)
- Database choice: SQLite (default, no extra config) or MySQL/PostgreSQL

### Pre-run setup
```bash
sudo mkdir /shotshare
sudo touch /shotshare/.env /shotshare/database.sqlite
sudo chown 82:82 /shotshare/.env /shotshare/database.sqlite
```
UID/GID 82 = `www-data` inside the container.

---

## Software-Layer Concerns

**Docker run (HTTPS — recommended for public deployments):**
```bash
docker run \
  -p 80:80 -p 443:443 \
  -e HOST=screenshots.example.com \
  -e FEATURE_UUID_ROUTES=true \
  -v shotshare_caddy_data:/data/caddy \
  -v shotshare_caddy_config:/config/caddy \
  -v shotshare_data:/app/storage/app/uploads \
  --mount type=bind,source=/shotshare/database.sqlite,target=/app/database/database.sqlite \
  --mount type=bind,source=/shotshare/.env,target=/app/.env \
  -d --restart unless-stopped --name shotshare \
  mdshack/shotshare:latest
```

**Docker run (HTTP — behind reverse proxy):**
```bash
docker run \
  -p 80:80 \
  -e HOST=":80" \
  -e FEATURE_UUID_ROUTES=true \
  -v shotshare_data:/app/storage/app/uploads \
  --mount type=bind,source=/shotshare/database.sqlite,target=/app/database/database.sqlite \
  --mount type=bind,source=/shotshare/.env,target=/app/.env \
  -d --restart unless-stopped --name shotshare \
  mdshack/shotshare:latest
```

**Key environment variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `localhost` | Public hostname; used by Caddy for SSL |
| `ALLOW_REGISTRATION` | `true` | Allow new user signups |
| `DB_CONNECTION` | `sqlite` | `sqlite`, `mysql`, `pgsql`, `sqlsrv` |
| `FEATURE_UUID_ROUTES` | `false` | Use UUIDs in URLs (hides sequential IDs) |
| `FEATURE_REACTIONS` | `true` | Enable upvote/downvote reactions |
| `FORCE_HTTPS` | `false` | Force HTTPS links when behind a proxy |
| `PHP_UPLOAD_MAX_FILESIZE` | `2M` | Max upload size |
| `FEATURE_FOOTER` | `true` | Show "Made with ShotShare" footer |

**Artisan commands** (run inside container):
```bash
docker exec -it shotshare php artisan shotshare:clean-images
```

**Upgrade procedure:**
1. `docker pull mdshack/shotshare:latest`
2. Stop and remove old container, run new one with same volumes/mounts
3. Check release notes — database migrations run automatically on startup

---

## Gotchas

- **File ownership is critical** — `/shotshare/.env` and `database.sqlite` must be owned by UID/GID 82; wrong permissions cause silent failures
- **Migration note for pre-1.5.1 users** — the database mount changed from a directory to a file bind; migrate `database.sqlite` manually
- **`FORCE_HTTPS=true` needed behind reverse proxy** — without it, generated share links will use `http://` even when served over HTTPS
- **SQLite is fine for personal use** — switch to MySQL/PostgreSQL for multi-user high-traffic deployments
- **`FEATURE_FOOTER=true` by default** — removing the footer is allowed but the author asks you to keep it to help the project

---

## Links
- GitHub: https://github.com/mdshack/shotshare
- Docker Hub: https://hub.docker.com/r/mdshack/shotshare
- Demo: https://demo.shotshare.dev/
