---
name: tinode
description: Tinode recipe for open-forge. Open-source instant messaging platform — Go backend with iOS, Android, and web clients. Docker install with MySQL or PostgreSQL. Upstream: https://github.com/tinode/chat
---

# Tinode

Open-source instant messaging platform. Backend written in Go; native clients for iOS (Swift), Android (Java), and a React web app. Designed as a modern, self-hosted replacement for XMPP/Jabber — think open-source WhatsApp or Telegram.

13,282 stars · GPL-3.0 (server) / Apache-2.0 (clients)

Upstream: https://github.com/tinode/chat
Docker docs: https://github.com/tinode/chat/blob/master/docker/README.md
Install guide: https://github.com/tinode/chat/blob/master/INSTALL.md
API docs: https://github.com/tinode/chat/blob/master/docs/API.md

## What it is

Tinode provides a complete self-hosted messaging stack:

- **Real-time messaging** — WebSocket (JSON) or gRPC (protobuf) wire transport
- **Clients** — iOS app, Android app, React web app, CLI
- **P2P and group chats** — Direct messages and multi-user topics
- **Push notifications** — FCM (Android/Web) and APNS (iOS) integration
- **File transfers** — Image and file sharing between users
- **Chatbots** — Scriptable bot API
- **gRPC support** — Client libraries for C++, C#, Go, Java, Node, PHP, Python, Ruby, Objective-C
- **Database backends** — MySQL, PostgreSQL, MongoDB, RethinkDB

Not XMPP-compatible. Not a Slack replacement — focused on end-user messaging.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker (recommended) | https://github.com/tinode/chat/blob/master/docker/README.md | Easiest — DB + server in containers |
| Binary releases | https://github.com/tinode/chat/releases | Bare metal |
| Build from source | https://github.com/tinode/chat/blob/master/INSTALL.md | Development |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| db | "Database backend: MySQL, PostgreSQL, or MongoDB?" | All |
| db_pass | "Database password?" | MySQL/PostgreSQL |
| port | "Expose Tinode on which host port? (default: 6060)" | All |
| domain | "Domain for reverse proxy (HTTPS)?" | Production |

## Docker install

Upstream: https://github.com/tinode/chat/blob/master/docker/README.md

### With PostgreSQL

    # 1. Create a bridge network
    docker network create tinode-net

    # 2. Start PostgreSQL
    docker run -d \
      --name postgres \
      --network tinode-net \
      --restart always \
      -e POSTGRES_PASSWORD=postgres \
      -v tinode-pg-data:/var/lib/postgresql/data \
      postgres:13

    # 3. Start Tinode server
    docker run -d \
      --name tinode-srv \
      --network tinode-net \
      --restart always \
      -p 6060:6060 \
      tinode/tinode-postgres:latest

The container initializes the database schema on first run.

### Docker Compose (PostgreSQL)

    services:
      postgres:
        image: postgres:13
        restart: always
        environment:
          POSTGRES_PASSWORD: postgres
        volumes:
          - pg_data:/var/lib/postgresql/data
        networks:
          - tinode-net

      tinode:
        image: tinode/tinode-postgres:latest
        restart: always
        depends_on:
          - postgres
        ports:
          - "6060:6060"
        networks:
          - tinode-net

    networks:
      tinode-net:

    volumes:
      pg_data:

### Access

After startup (allow 30s for DB init on first run):

- Web app: http://localhost:6060
- API endpoint: http://localhost:6060/v0/

## Environment variables

| Variable | Description |
|---|---|
| `STORE_USE_ADAPTER` | DB adapter when using tinode/tinode multi-DB image: mysql, postgres, mongodb, rethinkdb |
| `TINODE_AUTH_TOKEN_KEY` | Secret key for JWT auth tokens |
| `FCM_SENDER_ID` / `FCM_CRED_FILE` | Firebase Cloud Messaging push notifications |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USERNAME` / `SMTP_PASSWORD` | Email for password reset |

Full config: https://github.com/tinode/chat/blob/master/server/tinode.conf

## Reverse proxy (HTTPS)

Caddy:

    tinode.example.com {
        reverse_proxy localhost:6060
    }

Nginx needs WebSocket upgrade headers:

    location / {
        proxy_pass http://localhost:6060;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

## Mobile clients

- Android: https://github.com/tinode/tindroid
- iOS: https://github.com/tinode/ios
- Web app: served at root URL by the Tinode server

## Upgrade

    docker pull tinode/tinode-postgres:latest
    docker stop tinode-srv && docker rm tinode-srv
    # Re-run docker run command — DB data is in a named volume, persisted

## Gotchas

- **Container name = DB hostname** — Tinode connects to the DB by container name (postgres, mysql, mongodb). Do not rename the DB container without updating Tinode config.
- **First-run DB init takes ~30s** — On first start, schema is created and demo data loaded. The server may appear unresponsive briefly.
- **WebSocket proxy headers required** — Nginx/Caddy must upgrade WebSocket connections. Without `Upgrade`/`Connection` headers, real-time messaging fails silently.
- **Push notifications require Firebase/APNS config** — Disabled by default. Set FCM credentials for Android/Web push.
- **Beta-quality** — Self-described as "feature-complete and stable but probably with a few bugs." Good for internal/community use.
- **Not yet federated** — All users must be on the same Tinode server. Cross-server federation is a future goal, not yet implemented.
- **MySQL 5.7 / PostgreSQL 13+** — These specific versions are tested; newer should work but verify with release notes.

## Links

- GitHub: https://github.com/tinode/chat
- Docker guide: https://github.com/tinode/chat/blob/master/docker/README.md
- Install guide: https://github.com/tinode/chat/blob/master/INSTALL.md
- API docs: https://github.com/tinode/chat/blob/master/docs/API.md
- Android client: https://github.com/tinode/tindroid
- iOS client: https://github.com/tinode/ios
- Web client: https://github.com/tinode/webapp
- Docker Hub: https://hub.docker.com/r/tinode/
