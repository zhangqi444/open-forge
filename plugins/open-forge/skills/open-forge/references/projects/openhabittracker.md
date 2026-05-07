---
name: openhabittracker
description: OpenHabitTracker recipe for open-forge. Self-hosted habit, task, and note tracker with time tracking, calendar view, and completion statistics. .NET Blazor Server. Docker. GPL-3.0. Source: https://github.com/Jinjinov/OpenHabitTracker
---

# OpenHabitTracker

Self-hosted habit, task, and note tracker. Tracks recurring habits with streaks, one-off tasks with due dates, and freeform notes. Includes time tracking, a calendar view, and completion statistics. Single-user app. Built with .NET Blazor Server. Docker. GPL-3.0 licensed.

Upstream: https://github.com/Jinjinov/OpenHabitTracker | Docker Hub: https://hub.docker.com/r/jinjinov/openhabittracker

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Official method |
| Any | Docker run | Single container |
| Any | .NET (manual) | Build from source |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | APPSETTINGS_USERNAME | Login username (default: admin) |
| config | APPSETTINGS_EMAIL | Login email (default: admin@admin.com) |
| config | APPSETTINGS_PASSWORD | Login password (default: admin -- change immediately) |
| config | APPSETTINGS_JWT_SECRET | Strong random secret for JWT signing (min 32 bytes recommended) |
| config | Port | Host port to map to container port 8080 (default: 5050) |

Generate a JWT secret on Linux/macOS:

```bash
openssl rand -base64 32
```

On Windows PowerShell:

```powershell
[System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

## Software-layer concerns

- Single-user: OpenHabitTracker is designed for one user per instance. There is no multi-user or team mode.
- Data persistence: app data stored under /app/.OpenHabitTracker in the container. Must be persisted via a bind mount or named volume.
- JWT secret: used to sign authentication tokens. If changed, all active sessions are invalidated.
- Blazor Server: renders on the server and streams UI updates over WebSocket. Requires a stable connection; not suitable for very high-latency environments.

## Install -- Docker Compose

Create a .env file:

```
APPSETTINGS_USERNAME=admin
APPSETTINGS_EMAIL=admin@example.com
APPSETTINGS_PASSWORD=changeme
APPSETTINGS_JWT_SECRET=your-extremely-strong-secret-key
```

docker-compose.yml:

```yaml
services:
  openhabittracker:
    image: jinjinov/openhabittracker:latest
    restart: unless-stopped
    ports:
      - "5050:8080"
    environment:
      - AppSettings__UserName=${APPSETTINGS_USERNAME}
      - AppSettings__Email=${APPSETTINGS_EMAIL}
      - AppSettings__Password=${APPSETTINGS_PASSWORD}
      - AppSettings__JwtSecret=${APPSETTINGS_JWT_SECRET}
    volumes:
      - ./.OpenHabitTracker:/app/.OpenHabitTracker
```

```bash
docker compose up -d
# Access at http://yourserver:5050
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- Change the default password immediately: default credentials (admin / admin) are well-known. Set APPSETTINGS_PASSWORD to a strong password before first run.
- JWT secret must be strong: a weak or short secret can be brute-forced. Use at least 32 random bytes (base64-encoded is fine).
- Data directory bind mount: without the volume mount, container restarts wipe all your habit and task data.
- Single-user limitation: if you need multiple users, run separate instances (separate ports, separate data directories).

## Links

- Source: https://github.com/Jinjinov/OpenHabitTracker
- Docker Hub: https://hub.docker.com/r/jinjinov/openhabittracker
- Container registry: https://github.com/Jinjinov/OpenHabitTracker/pkgs/container/openhabittracker
