# SAMA

**Next-gen self-hosted chat server** — Simple but Advanced Messaging Alternative. Custom messaging protocol (alternative to XMPP), built on Node.js/uWebSockets.js with MongoDB and Redis. Includes web client, Flutter mobile client, and push notification daemon.

**Official site:** https://samacloud.io  
**Source (server):** https://github.com/SAMA-Communications/sama-server  
**Source (web client):** https://github.com/SAMA-Communications/sama-client  
**Source (Flutter app):** https://github.com/SAMA-Communications/sama-client-flutter  
**Docs:** https://docs.samacloud.io  
**Demo:** https://app.samacloud.io/demo  
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose | Primary recommended method; all services included |

---

## System Requirements

- Docker + Docker Compose
- MongoDB
- Redis
- S3-compatible storage (MinIO or AWS S3) for file attachments

---

## Inputs to Collect

| Input | Description |
|-------|-------------|
| MongoDB URI | Connection string for MongoDB |
| Redis URL | Redis connection URL |
| S3 endpoint / bucket / credentials | For file/media storage |
| Push notification credentials | FCM (Android) / APNs (iOS) for push daemon |
| Domain / public URL | For nginx and client configuration |

---

## Software-layer Concerns

### Docker Compose
The repository uses a modular docker-compose setup with service files in `prefs/docker-compose/services/`:

```bash
git clone https://github.com/SAMA-Communications/sama-server
cd sama-server
# Copy and configure environment files
cp .env.example .env
# Edit .env with your MongoDB URI, Redis URL, S3 config, etc.
docker compose up -d
```

### Services in the stack
| Service | Purpose |
|---------|---------|
| `sama-server` | Core chat server (Node.js / uWebSockets.js) |
| `sama-client` | Web frontend client |
| `sama-push-daemon` | Push notification delivery (FCM/APNs) |
| `nginx` | Reverse proxy |
| `mongo` | MongoDB (message/user storage) |
| `redis` | Caching and pub/sub |
| `s3` / `s3-service` | MinIO S3-compatible storage |

### Clients
- **Web app:** https://github.com/SAMA-Communications/sama-client
- **Flutter (iOS/Android/desktop):** https://github.com/SAMA-Communications/sama-client-flutter
- **Public cloud test:** https://app.samacloud.io

### API
Full API reference at https://docs.samacloud.io — covers Users, Conversations, Messages, Activities, Address Book, Push Notifications APIs.

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Custom protocol** — SAMA uses its own messaging protocol, not XMPP or Matrix. Only SAMA clients are compatible; standard IRC/XMPP clients will not work.
- **Full stack required.** MongoDB + Redis + S3 must all be running. Use the provided Docker Compose setup to avoid configuration errors.
- **Push daemon needs platform credentials.** FCM API key (Android) and APNs certificate (iOS) must be configured separately for mobile push notifications.
- **Frontend must be rebuilt** if you change the API server URL — the default build points to the production cloud. Follow the docker-compose deployment guide.

---

## References

- Deployment guide: https://docs.samacloud.io/deployment/docker-server-setup/
- Upstream README: https://github.com/SAMA-Communications/sama-server#readme
- Full docs: https://docs.samacloud.io
