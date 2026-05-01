# Fenrus

**Personal home page / new tab dashboard built with .NET — quick access to your self-hosted apps with smart app integrations, search, and group management.**
GitHub: https://github.com/revenz/Fenrus

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Preferred method |
| Any Linux | Docker run | Single container |
| Any | .NET runtime | Requires ASP.NET Core Runtime 7.0+ |

---

## Inputs to Collect

### All phases
- `TZ` — timezone (e.g. America/New_York)
- Data volume path — host path to persist /app/data (LiteDB config + encryption key)
- Port — default 3000; override with `PORT` env var

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  fenrus:
    image: revenz/fenrus
    container_name: fenrus
    environment:
      - TZ=America/New_York
    volumes:
      - /path/to/data:/app/data
    ports:
      - 3000:3000
    restart: unless-stopped
```

### Docker run
```bash
docker run -d \
  --name=Fenrus \
  -e TZ=America/New_York \
  -p 3000:3000 \
  -v /path/to/data:/app/data \
  --restart unless-stopped \
  revenz/fenrus:latest
```

### Custom port
```yaml
environment:
  - PORT=1234
```

### Data storage
- All configuration saved to a LiteDB file at `/app/data/Fenrus.db`
- An encryption key is stored alongside the DB to protect sensitive data
- Always mount `/app/data` to a persistent host volume

### Reverse proxy
Fenrus requires `X-Forwarded-Proto` and `X-Forwarded-For` headers when behind a reverse proxy (needed for OAuth callback URLs).
Key env vars:

| Variable | Default | Notes |
|----------|---------|-------|
| ReverseProxySettings__UseForwardedHeaders | false | Set true when behind proxy |
| ReverseProxySettings__KnownProxies | [] | Array of trusted proxy IPs |

### Ports
- `3000` — web UI

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Must mount `/app/data` or all config is lost on container restart
- When running behind a reverse proxy, enable `UseForwardedHeaders` and set `KnownProxies` or OAuth will fail
- Built on .NET 7 — if running natively (not Docker), install ASP.NET Core Runtime 7.0

---

## References
- GitHub: https://github.com/revenz/Fenrus#readme
