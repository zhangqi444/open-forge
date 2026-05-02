# Lurker

**What it is:** Self-hostable, read-only Reddit client with a focus on mobile rendering and minimal JavaScript. Features invite-only user management, account-based subreddit subscriptions, comment collapsing, dark/light mode respecting `prefers-color-scheme`, and no Reddit account required for access. SQLite-backed.

**Official URL:** https://github.com/oppiliappan/lurker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended |
| Any Linux host | Docker run | Single container |
| NixOS | systemd service via Nix flake | Native NixOS option |
| Any | Bun (manual) | Development / non-Docker path |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | Host port | Default `3000` |
| Deploy | Data directory | Mounted at `/data`; contains `lurker.db` (SQLite) |
| Optional | `LURKER_PORT` | Override listen port (default `3000`) |
| Optional | `LURKER_THEME` | CSS theme filename from `src/public/`; for custom themes |

---

## Software-Layer Concerns

### Docker image
```
ghcr.io/oppiliappan/lurker:latest
```

### docker-compose.yml
```yaml
version: '3'
services:
  lurker:
    image: ghcr.io/oppiliappan/lurker:latest
    container_name: lurker
    volumes:
      - ./lurker-data:/data
    ports:
      - "3000:3000"
    restart: unless-stopped
```

### Data directory
- SQLite database `lurker.db` is created in `/data` (inside container) on first run
- Create the host directory before starting: `mkdir lurker-data`
- **Database path is not configurable** — Lurker always writes `lurker.db` to the working directory mapped at `/data`

### First-run setup
1. Start the container — registrations are **open** on first start
2. Navigate to `/register` and create your account — this becomes the **admin** account
3. From the admin dashboard (click username → top-right), generate invite links for additional users
4. Optionally lock further registrations by not sharing invite links

### Environment variables
| Variable | Default | Description |
|----------|---------|-------------|
| `LURKER_PORT` | `3000` | Port to listen on |
| `LURKER_THEME` | _(built-in)_ | CSS theme filename in `src/public/` |

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

SQLite database persists in the mounted volume. No migration step documented.

---

## Gotchas

- **First user is admin** — registrations are open until the first user registers; deploy behind auth or create your account immediately after starting
- **Invite-only after setup** — additional users require admin-generated invite links; there is no open registration toggle
- **Read-only Reddit access** — Lurker uses Reddit's public API; no login to Reddit is needed or supported; posting/commenting is not possible
- **Database path hardcoded** — `lurker.db` is always in the working directory (`/data` when using Docker); the path cannot be changed via config
- **NixOS flake** — source repo is mirrored at `git.peppe.rs/web/lurker`; the NixOS service module uses that URL as its flake input

---

## Links

- GitHub: https://github.com/oppiliappan/lurker
- Container registry: ghcr.io/oppiliappan/lurker
