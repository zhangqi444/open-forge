# Astroluma

**Feature-rich self-hosted home lab dashboard built with MERN stack — links, todos, snippets, TOTP, network devices, IP cameras, and 20+ app integrations.**
Official site: https://getastroluma.com
GitHub: https://github.com/Sanjeet990/Astroluma

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended — MERN stack with MongoDB |

---

## Inputs to Collect

### Required
- `SECRET_KEY` — JWT signing secret (change from default)
- `MONGODB_URI` — MongoDB connection string
- `PORT` — application port (default: 8000)

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  app:
    image: sanjeet990/astroluma:latest
    container_name: astroluma
    environment:
      PORT: 8000
      NODE_ENV: production
      SECRET_KEY: your-secret-key-here
      MONGODB_URI: mongodb://localhost:27017/astroluma
    volumes:
      - uploads_data:/app/storage/uploads
      - uploads_apps:/app/storage/apps
    depends_on:
      - mongodb
    restart: always
    network_mode: host

  mongodb:
    image: mongo:6.0
    container_name: astroluma_mongodb
    volumes:
      - mongo_data:/data/db
    restart: always

volumes:
  mongo_data:
  uploads_data:
  uploads_apps:
```
Note: uses network_mode: host by default — adjust if you want isolated networking.

Use the compose generator for customized configs: https://getastroluma.com/compose

### Ports
- `8000` — web UI (host networking mode, direct)

### Key features
- Multi-user support with individual instances per user
- Links/bookmarks with nested categories
- Todo list manager, code snippet manager
- TOTP (2FA) code generator
- Network device scanner (IPv4), Wake-on-LAN, device status monitoring
- IP camera stream support
- Weather integration
- 20+ third-party app integrations: Sonarr, Immich, Portainer, Proxmox, Uptime Kuma, Nextcloud, Nginx Proxy Manager, and more
- 15 built-in themes

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Default compose uses `network_mode: host` — MongoDB is only accessible locally; adjust if running in a dedicated network
- Change SECRET_KEY from the example before going to production
- MongoDB 6.0 is the tested/recommended version
- Full installation docs: https://getastroluma.com/docs/getting-started/installation/

---

## References
- Compose generator: https://getastroluma.com/compose
- Installation guide: https://getastroluma.com/docs/getting-started/installation/
- GitHub: https://github.com/Sanjeet990/Astroluma#readme
