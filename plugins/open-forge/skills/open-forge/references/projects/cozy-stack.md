---
name: cozy-stack
description: Recipe for Cozy Stack (Twake Workplace) — personal cloud platform with file sync, contacts, calendar, photos, and a web app store.
---

# Cozy Stack (Twake Workplace)

Personal cloud platform providing file sync/sharing, contacts, calendar, photos, and a curated store of web apps installable per user. Single Go binary (the "stack") serves as the core server. Each user gets their own isolated CouchDB database and app sandbox. Rebranded as Twake Workplace. Upstream: <https://github.com/cozy/cozy-stack>. Docs: <https://docs.cozy.io/en/cozy-stack/>. License: AGPL-3.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker / Docker Compose | <https://docs.cozy.io/en/tutorials/selfhosting/> | Yes | Recommended self-hosted setup |
| Binary | <https://github.com/cozy/cozy-stack/releases> | Yes | Bare-metal; single Go binary |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Domain for Cozy instance? | Domain (e.g. cozy.example.com) | Required; each user gets a subdomain |
| infra | Wildcard DNS/TLS configured? | Boolean | Required; users get <name>.cozy.example.com |
| software | Admin passphrase? | Sensitive string | Required for admin API |
| software | CouchDB URL + credentials? | http://user:pass@host:5984 | Required; external CouchDB or bundled |
| software | SMTP credentials? | host:port + user/pass | Recommended for email flows |

## Software-layer concerns

### Architecture

Cozy Stack is a single binary that:
- Serves the web apps (from the app store or custom) in per-user sandboxed iframes
- Manages per-user CouchDB databases (one DB per doctype per user)
- Handles OAuth2/OIDC authentication
- Provides a REST API for all data operations

Each user's "Cozy" is a subdomain: `alice.cozy.example.com`, `bob.cozy.example.com`.

### Docker Compose

```yaml
services:
  couchdb:
    image: couchdb:3
    container_name: cozy-couchdb
    restart: unless-stopped
    environment:
      COUCHDB_USER: cozy
      COUCHDB_PASSWORD: couchdbpassword
    volumes:
      - couchdb-data:/opt/couchdb/data

  cozy:
    image: cozy/cozy-stack:latest
    container_name: cozy-stack
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "6060:6060"   # admin API — internal only
    environment:
      COZY_COUCHDB_URL: http://cozy:couchdbpassword@couchdb:5984/
      COZY_HOST: 0.0.0.0
      COZY_PORT: 8080
      COZY_ADMIN_PASSPHRASE: adminpassphrase
      COZY_FS_DEFAULT_LAYOUT: "2"
    volumes:
      - cozy-data:/var/lib/cozy
      - ./cozy.yaml:/etc/cozy/cozy.yaml:ro
    depends_on:
      - couchdb

volumes:
  couchdb-data:
  cozy-data:
```

### cozy.yaml (configuration)

```yaml
host: 0.0.0.0
port: 8080
admin:
  host: 0.0.0.0
  port: 6060

couchdb:
  url: http://cozy:password@couchdb:5984/

fs:
  url: file:///var/lib/cozy/

mail:
  host: smtp.example.com
  port: 587
  username: cozy@example.com
  password: smtppassword

log:
  level: info
```

### Creating an instance (first user)

```bash
# Via admin API
curl -X POST http://admin:adminpassphrase@localhost:6060/instances \
  -d 'Domain=alice.cozy.example.com&Locale=en&Timezone=UTC&Email=alice@example.com&PublicName=Alice'
```

### DNS requirement

Each Cozy user needs a subdomain. Configure:
- `*.cozy.example.com` → your server IP (wildcard A record)
- Wildcard TLS cert (Let's Encrypt wildcard via DNS challenge, or Caddy with ACME DNS provider)

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

After upgrading, run: `cozy-stack instances ls` to verify all instances are healthy.

## Gotchas

- Wildcard DNS and TLS are required: every user needs a unique subdomain. Without wildcard DNS, multi-user hosting is not possible.
- Admin API (port 6060) must not be exposed publicly: it can create/delete instances and manage all users.
- CouchDB is the only supported database: Cozy uses CouchDB's replication API for mobile sync. PostgreSQL is not supported.
- App installs: apps are fetched from the Cozy app registry. Air-gapped installs need a local registry mirror.
- Rebranding: the project is now called "Twake Workplace" but the code/images remain under the `cozy` namespace.

## Links

- GitHub: <https://github.com/cozy/cozy-stack>
- Docs: <https://docs.cozy.io/en/cozy-stack/>
- Self-hosting tutorial: <https://docs.cozy.io/en/tutorials/selfhosting/>
- Docker Hub: <https://hub.docker.com/r/cozy/cozy-stack>
- App store: <https://cozy.io/en/apps/>
