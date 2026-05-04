# Rocket.Chat

Open-source team messaging and collaboration platform. Rocket.Chat is a self-hosted alternative to Slack/Teams. Supports channels, direct messages, voice/video calls, file sharing, bots, integrations, and omnichannel customer messaging. Also available as a SaaS; self-hosted version is fully featured.

**Official site:** https://rocket.chat  
**Source:** https://github.com/RocketChat/Rocket.Chat  
**Upstream docs:** https://docs.rocket.chat/deploy/deploy-rocket.chat  
**License:** MIT (core); AGPL-3.0 (Enterprise features)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary self-hosted method |
| Kubernetes | Helm chart | Official chart available |

---

## Inputs to Collect

| Variable | Description | Default |
|----------|-------------|---------|
| `ROOT_URL` | Public URL of your Rocket.Chat instance | `http://localhost:3000` |
| `PORT` | Internal app port | `3000` |
| `HOST_PORT` | Host port to bind | `3000` |
| `BIND_IP` | Host IP to bind | `0.0.0.0` |
| `RELEASE` | Docker image tag | `latest` |
| `MONGODB_VERSION` | MongoDB version | `8.2` |

---

## Software-Layer Concerns

### Docker Compose
```yaml
volumes:
  mongodb_data:

services:
  rocketchat:
    image: registry.rocket.chat/rocketchat/rocket.chat:latest
    restart: always
    environment:
      MONGO_URL: mongodb://mongodb:27017/rocketchat?replicaSet=rs0
      ROOT_URL: https://chat.example.com
      PORT: 3000
      DEPLOY_METHOD: docker
    ports:
      - "3000:3000"
    depends_on:
      - mongodb

  mongodb:
    image: mongodb/mongodb-community-server:8.2-ubi8
    restart: on-failure
    environment:
      MONGODB_REPLICA_SET_NAME: rs0
      MONGODB_PORT_NUMBER: 27017
      MONGODB_INITIAL_PRIMARY_HOST: mongodb
    entrypoint: |
      bash -c "mongod --replSet rs0 --bind_ip_all &
        sleep 2;
        until mongosh --eval \"db.adminCommand('ping')\"; do sleep 1; done;
        mongosh --eval \"rs.initiate({_id:'rs0',members:[{_id:0,host:'mongodb:27017'}]})\";
        wait"
    volumes:
      - mongodb_data:/data/db
```

### MongoDB replica set requirement
Rocket.Chat requires MongoDB with a replica set (`replicaSet=rs0`). The compose file above handles initialization automatically via the entrypoint script. Single-node replica sets are supported.

### Official compose repo
The canonical compose is maintained separately from the main source repo:
```sh
git clone https://github.com/RocketChat/rocketchat-compose.git
cd rocketchat-compose
cp .env.example .env
# Edit ROOT_URL and other vars
docker compose up -d
```

### Admin setup
On first start, visit `http://<host>:3000` to complete the setup wizard and create the admin account.

### Data directory
- MongoDB volume: all messages, files, and config
- Uploaded files (GridFS) stored in MongoDB by default, or configure S3/external storage

---

## Upgrade Procedure

1. Check [release notes](https://github.com/RocketChat/Rocket.Chat/releases) for breaking changes
2. Back up MongoDB: `docker exec mongodb mongodump --out /backup`
3. Pull new image: `docker compose pull`
4. Restart: `docker compose up -d`
5. Rocket.Chat runs migrations automatically on startup

---

## Gotchas

- **MongoDB replica set is mandatory** — Rocket.Chat will not start without a replica set; even single-node deployments must use `?replicaSet=rs0`
- **ROOT_URL must be set correctly** — wrong ROOT_URL breaks OAuth logins, email links, and WebSocket connections
- **MongoDB version pinning** — always pin to a specific MongoDB version tag; `latest` can break between major versions
- **File storage defaults to GridFS** — for large deployments, configure S3-compatible external file storage to avoid bloating MongoDB
- **Traefik labels in compose** — the official compose file includes Traefik routing labels; remove them if you use a different reverse proxy

---

## Links
- Upstream README: https://github.com/RocketChat/Rocket.Chat
- Compose repo: https://github.com/RocketChat/rocketchat-compose
- Deploy docs: https://docs.rocket.chat/deploy/deploy-rocket.chat/deploy-with-docker-and-docker-compose
