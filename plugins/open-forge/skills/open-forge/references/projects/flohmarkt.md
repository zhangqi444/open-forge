# flohmarkt

**What it is:** Federated, decentralized self-hosted classified ads / flea-market platform. Built on ActivityPub — ads are notes in the Fediverse and can be shared to Mastodon, Pleroma, and other flohmarkt instances. Location-aware (coordinates + radius nudge local communities). Email confirmation at signup; registration can be disabled after initial setup.

**Official URL:** https://codeberg.org/flohmarkt/flohmarkt  
**Wiki / docs:** https://codeberg.org/flohmarkt/flohmarkt/wiki

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (prebuilt) | Recommended for production |
| Any Linux host | Docker Compose (build from source) | For development |
| NixOS | NixOS module (flake) | Native NixOS option |
| Kubernetes | Helm chart | Chart in `chart/` directory |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | `FLOHMARKT_INSTANCE_NAME` | Short identifier for your instance |
| Deploy | `FLOHMARKT_EXTERNAL_URL` | Full public URL (e.g. `https://flohmarkt.example.com`) — required for ActivityPub |
| Deploy | `FLOHMARKT_DB_USER` / `FLOHMARKT_DB_PASSWORD` | CouchDB credentials |
| Deploy | `FLOHMARKT_DB_NAME` | Database name (default `flohmarkt`) |
| Deploy | `FLOHMARKT_MAIL_FROM` | Sender address for registration confirmation emails |
| Deploy | SMTP settings | `FLOHMARKT_SMTP_SERVER`, `FLOHMARKT_SMTP_PORT`, `FLOHMARKT_SMTP_USER`, `FLOHMARKT_SMTP_PASSWORD` |
| Optional | `FLOHMARKT_TILECACHE_SERVER_URL` | Tile server URL (default: `https://tile.openstreetmap.org`) |
| Optional | `FLOHMARKT_TILECACHE_SIZE` | Tile cache size (default: `10_000`) |

---

## Software-Layer Concerns

### Docker image
```
codeberg.org/flohmarkt/flohmarkt:latest
```
> **⚠️ Use versioned tags for production**, e.g. `codeberg.org/flohmarkt/flohmarkt:0.10.0`. The `master` branch is explicitly unstable and not recommended for production use.

### docker-compose_prod_prebuilt.yaml (production)
```yaml
services:
  database:
    image: docker.io/library/couchdb:3.3
    environment:
      - COUCHDB_USER=${FLOHMARKT_DB_USER}
      - COUCHDB_PASSWORD=${FLOHMARKT_DB_PASSWORD}
    volumes:
      - ./couchdb_data:/opt/couchdb/data
    healthcheck:
      test: ["CMD", "curl", "--fail", "http://localhost:5984"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: "always"

  init:
    command: initdb
    image: codeberg.org/flohmarkt/flohmarkt:latest
    env_file:
      - .env
    volumes:
      - ./flohmarkt_data:/var/lib/flohmarkt
    depends_on:
      database:
        condition: service_healthy
    restart: "no"

  web:
    command: web
    image: codeberg.org/flohmarkt/flohmarkt:latest
    env_file:
      - .env
    volumes:
      - ./flohmarkt_data:/var/lib/flohmarkt
    ports:
      - "8000:8000"
    depends_on:
      database:
        condition: service_healthy
      init:
        condition: service_completed_successfully
    restart: "always"
```

### .env (copy from `example.env`)
```env
LANG=en_US.UTF-8
FLOHMARKT_INSTANCE_NAME=myflea
FLOHMARKT_EXTERNAL_URL=https://flohmarkt.example.com
FLOHMARKT_DB_HTTPS=0
FLOHMARKT_DB_HOST=database
FLOHMARKT_DB_PORT=5984
FLOHMARKT_DB_NAME=flohmarkt
FLOHMARKT_DB_USER=admin
FLOHMARKT_DB_PASSWORD=your_couchdb_password
FLOHMARKT_MAIL_METHOD=smtp
FLOHMARKT_MAIL_FROM=noreply@example.com
FLOHMARKT_SMTP_SERVER=smtp.example.com
FLOHMARKT_SMTP_PORT=587
FLOHMARKT_SMTP_USER=smtp_user
FLOHMARKT_SMTP_PASSWORD=smtp_password
```

### Data directories
- CouchDB data: `./couchdb_data`
- flohmarkt uploads/data: `./flohmarkt_data`

### Reverse proxy
An nginx config example is provided at `nginx.conf.example` in the repo. The `FLOHMARKT_EXTERNAL_URL` must be reachable publicly for ActivityPub federation to work.

---

## Upgrade Procedure

```bash
# Update image tag in docker-compose or .env to the new release version
docker compose pull
docker compose up -d
```

Check the [RELEASE.md](https://codeberg.org/flohmarkt/flohmarkt/src/branch/master/RELEASE.md) for any migration notes specific to each release.

---

## Gotchas

- **Never run the `master` branch in production** — the README explicitly warns this will likely cause data loss; only run tagged releases (e.g. `0.10.0`)
- **`init` service is one-shot** — it initialises CouchDB schema and exits; `restart: "no"` is intentional; re-running it on an existing database is safe but unnecessary
- **`FLOHMARKT_EXTERNAL_URL` must be publicly resolvable** — ActivityPub uses this URL to build actor IDs; changing it after first use will break federation
- **Email is required for registration** — flohmarkt sends confirmation emails; SMTP must be configured before users can register
- **Location is set at install time** — coordinates and radius for local nudging are configured once; consult wiki for details

---

## Links

- Codeberg: https://codeberg.org/flohmarkt/flohmarkt
- Wiki / installation docs: https://codeberg.org/flohmarkt/flohmarkt/wiki
- Known instances: https://codeberg.org/flohmarkt/flohmarkt/wiki/flohmarkt-instances
- `example.env`: https://codeberg.org/flohmarkt/flohmarkt/src/branch/master/example.env
