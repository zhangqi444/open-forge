# Our Shopping List

**Collaborative shared list app** — real-time synchronized shopping lists and todo lists for household or group use. Multiple boards, multiple lists per board, mobile-first UI with swipeable items, PWA support.

**Source:** https://github.com/nanawel/our-shopping-list  
**Demo:** https://osl.lanterne-rouge.info/  
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose (app + MongoDB) | Primary recommended method |

---

## System Requirements

- Docker + Docker Compose
- MongoDB (included in compose setup)

---

## Inputs to Collect

| Input | Description | Default |
|-------|-------------|---------|
| `LISTEN_PORT` | Internal app port | `8080` |
| `HTTP_PORT` | External port | `80` |
| `MONGODB_HOST` | MongoDB hostname | `mongodb` |
| `MONGODB_PORT` | MongoDB port | `27017` |
| `MONGODB_DB` | Database name | `osl` |
| `VITE_APP_SINGLEBOARD_MODE` | `1` for single-board (v1 behavior), `0` for multi-board | `0` |

---

## Software-layer Concerns

### Docker Compose
```yaml
services:
  app:
    image: ourshoppinglist/our-shopping-list:latest
    ports:
      - '80:8080'
    environment:
      - LISTEN_PORT=8080
      - MONGODB_HOST=mongodb
      - MONGODB_DB=osl
      # Single-board mode (simpler, v1 behavior):
      # - VITE_APP_SINGLEBOARD_MODE=1
    depends_on:
      - mongodb
    restart: unless-stopped

  mongodb:
    image: mongo:6
    volumes:
      - osl_mongo:/data/db
    restart: unless-stopped

volumes:
  osl_mongo:
```

Access at `http://localhost`.

See the [provided example compose file](https://github.com/nanawel/our-shopping-list/blob/master/doc/docker-compose.yml) for the full reference.

### Docker CLI (minimal)
```bash
docker run --detach \
  --name our-shopping-list \
  --link mymongo:mongodb \
  --publish 80:8080 \
  ourshoppinglist/our-shopping-list
```

### Board modes
| Mode | Description |
|------|-------------|
| **Multi-board** (default) | Groups of lists under named boards; boards are shared by URL/slug |
| **Singleboard** (`VITE_APP_SINGLEBOARD_MODE=1`) | All lists visible to everyone; simpler, v1 behavior |

### Key app environment variables
| Variable | Description | Default |
|----------|-------------|---------|
| `LISTEN_PORT` | HTTP port inside container | `8080` |
| `MONGODB_HOST` | MongoDB host | `mongodb` |
| `MONGODB_PORT` | MongoDB port | `27017` |
| `MONGODB_DB` | MongoDB database name | `osl` |
| `BASE_URL` | Base path if not serving from `/` | — |
| `VITE_APP_SINGLEBOARD_MODE` | `1` = single board mode | `0` |
| `VITE_APP_BOARD_DELETION_ENABLED` | Allow deleting boards | `0` |
| `VITE_APP_DISABLE_PASTE_CSV` | Disable CSV paste mass-create feature | `0` |
| `VITE_APP_HOME_MESSAGE` | Custom message on home screen | — |

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

> ⚠️ **v1 → v2 migration required CLI steps** — see the README for board migration commands before upgrading from v1.

### v1 → v2 migration (singleboard)
```bash
docker compose exec app node cli.js board:create --singleboard
docker compose exec app node cli.js list:move-to-board --all --singleboard
```

---

## Gotchas

- **MongoDB has no auth support yet.** Do not expose MongoDB port externally.
- **v1 → v2 is a breaking migration.** Back up your MongoDB data before upgrading. Run the CLI migration steps above.
- **`VITE_APP_` prefix** — prior to v2, variables used `VUE_APP_` prefix. Update any old configs.
- **No user accounts.** Access control is by board URL/slug only — anyone with the link can edit. Use a reverse proxy with auth for sensitive lists.
- **Real-time sync** via WebSockets; requires sticky sessions if behind a load balancer.

---

## References

- Upstream README: https://github.com/nanawel/our-shopping-list#readme
- Demo: https://osl.lanterne-rouge.info/
- Example docker-compose.yml: https://github.com/nanawel/our-shopping-list/blob/master/doc/docker-compose.yml
