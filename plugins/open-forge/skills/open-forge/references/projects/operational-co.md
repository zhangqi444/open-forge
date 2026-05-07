---
name: Operational.co
description: Open-source event tracking and alerting tool. Receive push notifications and live timeline alerts from your product or infrastructure. MIT licensed.
website: https://operational.co
source: https://github.com/operational-co/operational.co
license: MIT
stars: 460
tags:
  - monitoring
  - alerting
  - notifications
  - events
  - observability
platforms:
  - JavaScript
  - Docker
---

# Operational.co

Operational is an open-source tool for tracking important events and receiving push notifications on your device. It provides a live timeline where your product or infrastructure can send alerts, giving you real-time visibility into what is happening. Think of it as a lightweight, self-hosted alternative to services like LogSnag or Beams for event-driven notifications.

Source: https://github.com/operational-co/operational.co
Website: https://operational.co

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker Compose | Recommended |
| Any Linux VM / VPS | Node.js | Native install |

## Inputs to Collect

**Phase: Planning**
- Port to expose (check repo for default)
- Database backend (check repo for requirements)
- API key / credentials for your product to send events

## Software-Layer Concerns

**Docker Compose:**

```bash
git clone https://github.com/operational-co/operational.co
cd operational.co
# Copy and edit the environment file
cp .env.example .env
# Edit .env with your configuration
docker compose up -d
```

**Send an event via API:**

```bash
curl -X POST https://operational.example.com/api/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "name": "New user signup",
    "description": "user@example.com signed up",
    "icon": "🎉"
  }'
```

**Nginx reverse proxy:**

```nginx
server {
    listen 443 ssl;
    server_name operational.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

See the upstream README and docs for full environment variable reference and configuration options.

## Upgrade Procedure

1. `git pull` (or `docker pull` if using a registry image)
2. `docker compose down && docker compose up -d`
3. Check releases: https://github.com/operational-co/operational.co/releases

## Gotchas

- **Check upstream README**: The project's README at https://github.com/operational-co/operational.co is the authoritative source for current install steps and env vars — verify before deploying
- **Push notifications**: Operational supports device push notifications — configure the relevant push notification credentials (VAPID keys or similar) in .env
- **API key security**: Treat your API key like a password; it allows anyone to post events to your timeline
- **License**: MIT — verify the current LICENSE file in the repo for the most recent license terms

## Links

- Source: https://github.com/operational-co/operational.co
- Website: https://operational.co
- Releases: https://github.com/operational-co/operational.co/releases
