# Gaseous

**Self-hosted ROM and game title manager with in-browser emulation.**
Official site / wiki: https://github.com/gaseous-project/gaseous-server/wiki
GitHub: https://github.com/gaseous-project/gaseous-server

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose (separate containers) | Preferred — server + MariaDB |
| Any Linux | Docker (all-in-one container) | Built-in MariaDB; not recommended for production |

---

## Inputs to Collect

### All phases
- `DOMAIN` — public hostname (e.g. `gaseous.example.com`)
- `DATA_DIR` — host path for ROM and server data (e.g. `/opt/gaseous`)
- `DB_PASSWORD` — MariaDB/MySQL root password (e.g. `gaseous`)
- `TZ` — timezone (e.g. `Australia/Sydney`)
- `IGDB_API_KEY` — IGDB API key (required unless using Hasheous proxy)

---

## Software-Layer Concerns

### Config
- Config via environment variables (`TZ`, `dbhost`, `dbuser`, `dbpass`)
- IGDB API key required for game metadata; see https://api-docs.igdb.com/#account-creation

### Data
- MariaDB 11.1.2+ (preferred) or MySQL 8+ for metadata database
- Server data directory: `/home/gaseous/.gaseous-server` inside container (changed from `/root/.gaseous-server` in v2)
- ROMs added via the web UI Library Scan after mounting to container

### Ports
- `5198` — web UI

### Docker Compose (preferred)
```yaml
version: '2'
services:
  gaseous-server:
    container_name: gaseous-server
    image: gaseousgames/gaseousserver:latest
    restart: unless-stopped
    networks:
      - gaseous
    depends_on:
      - gsdb
    ports:
      - 5198:80
    volumes:
      - gs:/home/gaseous/.gaseous-server
    environment:
      - TZ=Australia/Sydney
      - dbhost=gsdb
      - dbuser=root
      - dbpass=gaseous
  gsdb:
    image: mariadb:latest
    networks:
      - gaseous
    environment:
      - MYSQL_ROOT_PASSWORD=gaseous
    volumes:
      - gsdb:/var/lib/mysql
networks:
  gaseous:
volumes:
  gs:
  gsdb:
```

---

## Upgrade Procedure

1. `docker compose pull`
2. `docker compose up -d`
3. Check logs: `docker compose logs -f gaseous-server`

---

## Gotchas

- v2 changed the internal data path from `/root/.gaseous-server` to `/home/gaseous/.gaseous-server` — update volume mapping when upgrading
- Moving from MySQL to MariaDB requires rebuilding the database from scratch (use Library Scan to re-import)
- All-in-one container has built-in MariaDB but receives less frequent security updates — use separate containers when possible
- Exposing to the internet is supported from v1.7.0+, but VPN/private access is still recommended

---

## References
- [Installation Wiki](https://github.com/gaseous-project/gaseous-server/wiki/Installation)
- [Adding ROMs Wiki](https://github.com/gaseous-project/gaseous-server/wiki/Adding-ROMs)
- [GitHub README](https://github.com/gaseous-project/gaseous-server#readme)
