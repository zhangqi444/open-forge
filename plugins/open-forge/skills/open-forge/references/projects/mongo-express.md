---
name: mongo-express
description: mongo-express recipe for open-forge. Web-based MongoDB admin UI built with Node.js, Express, and Bootstrap. Run as a Docker container alongside a MongoDB instance.
---

# mongo-express

Web-based MongoDB administration UI. Supports browsing databases, collections, and documents; running queries; importing/exporting data. Upstream: <https://github.com/mongo-express/mongo-express>. Docker Hub: <https://hub.docker.com/_/mongo-express>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Sidecar to MongoDB container on same Docker network |
| Standalone Docker | Same — run with `--network` pointing to MongoDB's network |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "What is your MongoDB host/container name?" | Default `mongo`; set via `ME_CONFIG_MONGODB_SERVER` |
| preflight | "MongoDB port?" | Default `27017` |
| preflight | "MongoDB admin username and password?" | `ME_CONFIG_MONGODB_ADMINUSERNAME` / `ME_CONFIG_MONGODB_ADMINPASSWORD` |
| preflight | "mongo-express basic-auth username and password?" | Protects the UI itself; set via `ME_CONFIG_BASICAUTH_USERNAME` / `ME_CONFIG_BASICAUTH_PASSWORD` |

## Docker Compose example

```yaml
version: "3.9"
services:
  mongo:
    image: mongo:7
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: changeme
    volumes:
      - mongo-data:/data/db

  mongo-express:
    image: mongo-express:latest
    restart: unless-stopped
    depends_on:
      - mongo
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_SERVER: mongo
      ME_CONFIG_MONGODB_PORT: 27017
      ME_CONFIG_MONGODB_ADMINUSERNAME: root
      ME_CONFIG_MONGODB_ADMINPASSWORD: changeme
      ME_CONFIG_BASICAUTH_USERNAME: admin
      ME_CONFIG_BASICAUTH_PASSWORD: changeme
      ME_CONFIG_OPTIONS_EDITORTHEME: ambiance

volumes:
  mongo-data:
```

## Software-layer concerns

- Default port: `8081`
- `ME_CONFIG_BASICAUTH_USERNAME` / `ME_CONFIG_BASICAUTH_PASSWORD` — enable always in production; without these the UI is open to anyone who can reach port 8081
- `ME_CONFIG_MONGODB_SERVER` must match the service name (or hostname) of the MongoDB container on the same Docker network
- `ME_CONFIG_OPTIONS_EDITORTHEME` — editor theme (e.g. `ambiance`, `dracula`); cosmetic only
- No persistent data of its own — stateless; all data lives in MongoDB

## Upgrade procedure

1. Pull new image: `docker compose pull mongo-express`
2. Restart: `docker compose up -d mongo-express`
3. No migration needed — stateless

## Gotchas

- **Auth is not on by default in older images** — always set `ME_CONFIG_BASICAUTH_USERNAME` and `ME_CONFIG_BASICAUTH_PASSWORD`
- Put behind a reverse proxy (Caddy / NGINX / Traefik) with TLS if exposed beyond localhost
- `depends_on` does not wait for MongoDB to be *ready* — use `restart: unless-stopped` so mongo-express retries on startup failures
- Large collections may be slow to render — the UI loads all documents in a page; use the query box to filter first

## Links

- GitHub: <https://github.com/mongo-express/mongo-express>
- Docker Hub: <https://hub.docker.com/_/mongo-express>
