# Traefik Log Dashboard

**Real-time analytics platform for Traefik reverse proxy logs — two-component system (lightweight Go agent + Vite web UI) with geographic visualization, charts, and mobile apps.**
GitHub: https://github.com/hhftechnology/traefik-log-dashboard
Discord: https://discord.gg/HDCt9MjyMJ

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Two containers: agent + dashboard |

---

## Inputs to Collect

### Required
- `TRAEFIK_LOG_DASHBOARD_AUTH_TOKEN` — secure token for agent API auth (set on agent, referenced by dashboard)
- Traefik log paths — host paths to Traefik access.log and traefik.log
- `AGENT_API_URL` — internal URL for dashboard to reach agent (e.g. http://traefik-agent:5000)

---

## Software-Layer Concerns

### Project structure
```bash
mkdir -p traefik-dashboard/data/{logs,positions,dashboard}
cd traefik-dashboard
```

### Docker Compose
```yaml
services:
  traefik-agent:
    image: hhftechnology/traefik-log-dashboard-agent:latest
    container_name: traefik-log-dashboard-agent
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - ./data/logs:/logs:ro
      - ./data/positions:/data
    environment:
      - TRAEFIK_LOG_DASHBOARD_ACCESS_PATH=/logs/access.log
      - TRAEFIK_LOG_DASHBOARD_ERROR_PATH=/logs/traefik.log
      - TRAEFIK_LOG_DASHBOARD_AUTH_TOKEN=your_secure_token_here
      - TRAEFIK_LOG_DASHBOARD_SYSTEM_MONITORING=true
      - TRAEFIK_LOG_DASHBOARD_LOG_FORMAT=json
    networks:
      - pangolin

  traefik-dashboard:
    image: hhftechnology/traefik-log-dashboard:latest
    container_name: traefik-log-dashboard
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data/dashboard:/app/data
      - ./data/positions:/data
    environment:
      - AGENT_API_URL=http://traefik-agent:5000
      - AGENT_API_TOKEN=your_secure_token_here
      - AGENT_NAME=Default Agent
      - NODE_ENV=production
      - PORT=3000
      - NEXT_PUBLIC_MAX_LOGS_DISPLAY=500
    depends_on:
      - traefik-agent
    networks:
      - pangolin

networks:
  pangolin:
    external: true
```

### Components
| Component | Image | Size |
|-----------|-------|------|
| Agent | hhftechnology/traefik-log-dashboard-agent | ~15 MB |
| Dashboard | hhftechnology/traefik-log-dashboard | ~151 MB |

### Traefik log format
Set `TRAEFIK_LOG_DASHBOARD_LOG_FORMAT=json` — requires Traefik configured to write JSON access logs.

### Ports
- `5000` — agent REST API
- `3000` — dashboard web UI

### Mobile apps
- iOS: App Store
- Android: Google Play

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- `AGENT_API_TOKEN` on the dashboard must match `TRAEFIK_LOG_DASHBOARD_AUTH_TOKEN` on the agent exactly
- Traefik must be configured for JSON access logging — plain text logs are not supported
- Mount logs read-only (`:ro`) on the agent — only the agent writes position files
- Pangolin auth is supported if you run behind a Pangolin reverse proxy

---

## References
- GitHub: https://github.com/hhftechnology/traefik-log-dashboard#readme
- Discord: https://discord.gg/HDCt9MjyMJ
