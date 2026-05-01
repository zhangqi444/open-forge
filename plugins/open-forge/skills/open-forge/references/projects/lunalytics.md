# Lunalytics

**Open source uptime monitoring tool — HTTP/S, TCP, PING, JSON Query, PUSH, and Docker container monitors, multi-user, customizable status pages, SSO, and 9+ notification channels.**
Official site: https://lunalytics.xyz
Demo: https://demo.lunalytics.xyz
GitHub: https://github.com/KSJaay/Lunalytics

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Docker run | Single container |
| Any Linux | Node.js (bare metal) | Node.js 22.14.0+ required |

---

## Inputs to Collect

### All phases
- Data volume path — persists SQLite/PostgreSQL data and logs

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  lunalytics:
    image: ksjaay/lunalytics:latest
    container_name: lunalytics
    ports:
      - '2308:2308'
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    restart: unless-stopped
```

### Docker run
```bash
docker run -d \
  -p 2308:2308 \
  -v /path/to/data:/app/data \
  -v /path/to/logs:/app/logs \
  ksjaay/lunalytics:latest
```

### Ports
- `2308` — web UI

### Monitor types
HTTP/S, TCP, PING, JSON Query, PUSH, Docker Containers

### Notification channels
Apprise, Discord, Email (SMTP), Home Assistant, Pushover, Slack, Telegram, Webhook

### SSO providers
Discord, Google, GitHub, Slack, Twitch, and custom OIDC (Authentik, Authelia, Keycloak, etc.)

### Database support
SQLite (default) and PostgreSQL

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Project is in beta — things may break; report issues on GitHub
- Default database is SQLite; PostgreSQL supported for larger deployments
- SSO via OIDC requires configuration of an external identity provider

---

## References
- Documentation: https://lunalytics.xyz
- GitHub: https://github.com/KSJaay/Lunalytics#readme
