# PinePods

**Rust-based self-hosted podcast management system with multi-user support, native mobile apps, and built-in gPodder sync.**
Official site: https://www.pinepods.online
GitHub: https://github.com/madeofpendletonwool/PinePods

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose (PostgreSQL) | Recommended |
| Any Linux | Docker Compose (MariaDB) | Alternative database |
| Kubernetes | Helm | Chart available in repo |

---

## Inputs to Collect

### All phases
- `SEARCH_API_URL` — podcast search endpoint (default: https://search.pinepods.online/api/search)
- `PEOPLE_API_URL` — PodPeople DB endpoint (default: https://people.pinepods.online)
- `HOSTNAME` — full public URL (e.g. https://podcasts.example.com)
- `DB_PASSWORD` — database password
- `TZ` — server timezone (e.g. America/New_York)
- `PUID` / `PGID` — host UID/GID for file ownership (run: id -u / id -g)
- Data paths: download directory, backup directory

---

## Software-Layer Concerns

### Key environment variables
- `DB_TYPE` — postgresql or mariadb
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- `VALKEY_HOST`, `VALKEY_PORT` — Valkey (Redis-compatible) cache
- `DEBUG_MODE` — set false in production

### Data dirs
- `/opt/pinepods/downloads` — podcast episode downloads
- `/opt/pinepods/backups` — backup exports

### Ports
- `8040` — main web UI

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d
3. docker compose logs -f pinepods

---

## Gotchas

- postgres:18 compatibility issue: if you hit a mount error on startup, use postgres:17 instead
- Set PUID/PGID to your host user (id -u / id -g) so downloaded files are accessible on the host
- Built-in gPodder server — compatible with AntennaPod and other gPodder clients
- Native iOS and Android apps available
- Valkey (Redis-compatible) is required as a cache layer

---

## References
- Documentation: https://www.pinepods.online/docs
- GitHub: https://github.com/madeofpendletonwool/PinePods#readme
