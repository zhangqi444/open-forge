---
name: tiledesk
description: Tiledesk recipe for open-forge. All-in-one customer engagement platform with live chat, AI chatbots, and omnichannel support (WhatsApp, web, Telegram, etc.). Alternative to Intercom, Zendesk, Tidio. Docker + Kubernetes. Source: https://github.com/Tiledesk/tiledesk
---

# Tiledesk

All-in-one open-source customer engagement platform. Provides live chat for your website, AI-powered chatbots, and omnichannel support across WhatsApp, Telegram, Facebook Messenger, web widget, and more. Build chatbot scripts once; they auto-adapt to each channel. Supports post-sales service, lead generation, and conversational app development. Node.js + MongoDB. Docker Compose and Kubernetes (Helm). MIT licensed.

Upstream: <https://github.com/Tiledesk/tiledesk> | Docs: <https://docs.tiledesk.com>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Recommended for dev/evaluation; beta |
| Kubernetes | Helm chart | Recommended for production |

> **Note:** The Docker Compose config is in **beta** and installs the latest dev version. For production, use Kubernetes.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | External base URL | Public URL of the Tiledesk instance, e.g. http://yourserver:8081 |
| config | External MQTT URL | WebSocket URL, e.g. ws://yourserver:8081 |
| config (optional) | Enterprise credentials | Required for enterprise Docker images (email info@tiledesk.com) |

## Software-layer concerns

### Architecture

| Service | Role |
|---|---|
| tiledesk-server | Node.js API backend |
| tiledesk-dashboard | React web UI |
| tiledesk-design-studio | Chatbot flow designer |
| chat21-server | Real-time chat server |
| chat21-http-server | HTTP API for chat21 |
| mongodb | Database |
| proxy | Nginx reverse proxy |

### Default credentials (change immediately)

- Admin email: `admin@tiledesk.com`
- Admin password: `superadmin`

## Install — Docker Compose

```bash
# Download Docker Compose file
curl https://raw.githubusercontent.com/Tiledesk/tiledesk-deployment/master/docker-compose/docker-compose.yml \
  --output docker-compose.yml

# Start (local access)
docker compose up

# Or with public IP
EXTERNAL_BASE_URL="http://YOUR_PUBLIC_IP:8081" \
EXTERNAL_MQTT_BASE_URL="ws://YOUR_PUBLIC_IP:8081" \
docker compose up -d

# Access at http://localhost:8081
# Login: admin@tiledesk.com / superadmin
```

## Install — Kubernetes (Helm)

```bash
# Add Tiledesk Helm repo
helm repo add tiledesk https://tiledesk.github.io/helm-charts/

# Install
helm install tiledesk tiledesk/tiledesk \
  --set externalBaseUrl=https://tiledesk.example.com

# See: https://github.com/Tiledesk/tiledesk/tree/master/helm
```

> For production Kubernetes: replace the bundled MongoDB container with MongoDB Atlas or an external MongoDB Replica Set for reliability.

## Upgrade procedure

Docker Compose:
```bash
docker compose pull
docker compose up -d
```

## Gotchas

- **Change default admin credentials immediately** after first login — `admin@tiledesk.com`/`superadmin` are widely known.
- **Docker Compose is beta** — the compose config installs the latest dev build and is not considered production-ready. Use Helm/Kubernetes for production.
- **EXTERNAL_BASE_URL and EXTERNAL_MQTT_BASE_URL** must be set correctly for the web widget and chatbot integrations to work from client browsers. Without these, the chat widget embeds on external sites will fail to connect.
- **Production MongoDB**: don't use the bundled MongoDB container in production. Use MongoDB Atlas or a self-managed external MongoDB with Replica Set for data safety.
- **Enterprise features** require enterprise Docker image credentials — contact info@tiledesk.com.

## Links

- Source: https://github.com/Tiledesk/tiledesk
- Deployment repo: https://github.com/Tiledesk/tiledesk-deployment
- Documentation: https://docs.tiledesk.com
- Discord: https://discord.gg/nERZEZ7SmG
- Forum: https://tiledesk.discourse.group
