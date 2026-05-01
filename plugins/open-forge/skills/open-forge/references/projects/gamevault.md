# GameVault

**Self-hosted gaming platform — organize and play DRM-free games from your file server, with a Windows desktop client. Think self-hosted Steam. Source-available (CC BY-NC-SA 4.0).**
Official site: https://gamevau.lt
GitHub (backend): https://github.com/Phalcode/gamevault-backend
GitHub (client app): https://github.com/Phalcode/gamevault-app

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose + PostgreSQL | Backend server |

Client app runs on Windows only.

---

## Inputs to Collect

### Required
- `DB_PASSWORD` — PostgreSQL password
- Games path — host path to DRM-free game files

---

## Software-Layer Concerns

### Docker Compose (backend server)
```yaml
services:
  gamevault-backend:
    image: phalcode/gamevault-backend:latest
    restart: unless-stopped
    environment:
      DB_HOST: db
      DB_USERNAME: gamevault
      DB_PASSWORD: your-secure-password
    ports:
      - 8080:8080
    volumes:
      - /path/to/games:/files   # mount your game library here

  db:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: gamevault
      POSTGRES_PASSWORD: your-secure-password
      POSTGRES_DB: gamevault
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### Client app
The Windows desktop client (GameVault App) connects to the backend server. Download from https://gamevau.lt or the GitHub releases page.

### Ports
- `8080` — backend API

### GameVault+
Premium tier available for additional features: https://gamevau.lt/gamevault-plus

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Only works with **DRM-free** games — not for cracked/pirated copies
- Client is Windows-only; backend runs on Linux via Docker
- License is CC BY-NC-SA 4.0 — not open source, commercial use prohibited
- Game files should be organized in a folder structure the backend can scan

---

## References
- Official site & docs: https://gamevau.lt
- Backend GitHub: https://github.com/Phalcode/gamevault-backend
- Client GitHub: https://github.com/Phalcode/gamevault-app#readme
