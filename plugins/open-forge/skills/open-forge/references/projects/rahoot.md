---
name: rahoot
description: Rahoot recipe for open-forge. Covers Docker Compose (recommended) and manual Node.js/pnpm install methods sourced from https://github.com/Ralex91/Rahoot.
---

# Rahoot

Open-source, self-hostable quiz platform inspired by Kahoot — host live quizzes for smaller events on your own server. Upstream: <https://github.com/Ralex91/Rahoot>. Docker image: `ralex91/rahoot`.

> ⚠️ **Project status: source unavailable.** Rahoot was removed from awesome-selfhosted in May 2026 because the upstream repository (https://github.com/Ralex91/Rahoot) was not found. The project may have been deleted, renamed, or made private. Verify current availability before deploying.

Single-container Node.js app (Next.js) listening on port `3000`. Configuration is file-based (`config/game.json` + `config/quizz/*.json`) — no external database required. Both the manager interface and the player-facing game UI are served from the same container.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (recommended) | <https://github.com/Ralex91/Rahoot/blob/main/compose.yml> | ✅ | Standard production path. Single container, persistent config volume. |
| Docker run (bare) | <https://github.com/Ralex91/Rahoot#with-docker> | ✅ | Quick test / minimal setup without a compose file. |
| Manual Node.js / pnpm | <https://github.com/Ralex91/Rahoot#without-docker> | ✅ | Development or environments without Docker. Node 22+ required. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | AskUserQuestion: Docker Compose / Docker run / Manual Node.js | Drives which section to follow. |
| preflight | "What host port should Rahoot listen on?" | Free-text, default 3000 | All methods. |
| config | "Set a manager password (replaces the default 'PASSWORD')?" | Free-text (sensitive) | All methods — upstream warns that manager access is blocked if the default value is not changed. |
| optional | "Enable a reverse proxy (Caddy / Nginx / Traefik) for TLS?" | AskUserQuestion: Yes / No | Recommended for public-facing deployments — Rahoot exposes plain HTTP. |

## Software-layer concerns

### Config paths

| File / dir | Purpose |
|---|---|
| config/game.json | Manager password + game-level settings |
| config/quizz/ | One JSON file per quiz |

The `config/` directory is bind-mounted from the host (or a named volume). It is created automatically with an example quiz on first run.

### Key config fields

Rahoot is configured via `config/game.json`, not environment variables. The critical field:

```json
{
  "managerPassword": "CHANGE_ME"
}
```

Upstream explicitly states: if `managerPassword` remains at the default "PASSWORD", access to the manager interface is **blocked**. Change it before exposing the instance.

### Data dirs

| Path (inside container) | Content |
|---|---|
| /app/config | All persistent state — game config + quizzes |

Mount this to the host to survive container restarts / upgrades.

## Install — Docker Compose (recommended)

Source: <https://github.com/Ralex91/Rahoot/blob/main/compose.yml>

```yaml
services:
  rahoot:
    image: ralex91/rahoot:latest
    ports:
      - "3000:3000"
    volumes:
      - ./config:/app/config
    restart: unless-stopped
```

```bash
# 1. Create a working directory
mkdir -p ~/rahoot && cd ~/rahoot

# 2. Save the compose file above as compose.yml

# 3. Start (first run creates ./config/ with an example quiz)
docker compose up -d

# 4. Update the manager password immediately
#    Edit ./config/game.json and change "managerPassword" from "PASSWORD" to something strong.
#    Restart is required for the change to take effect:
docker compose restart
```

Access:
- Player UI: http://host:3000
- Manager UI: http://host:3000/manager

## Install — Docker run (bare)

Source: <https://github.com/Ralex91/Rahoot#with-docker>

```bash
docker run -d \
  -p 3000:3000 \
  -v ./config:/app/config \
  ralex91/rahoot:latest
```

Same config-volume and password-change requirements apply.

## Install — Manual Node.js / pnpm

Source: <https://github.com/Ralex91/Rahoot#without-docker>

Requirements:
- Node.js 22 or higher
- pnpm (see https://pnpm.io/ for install)

```bash
# 1. Clone the repo
git clone https://github.com/Ralex91/Rahoot.git
cd Rahoot

# 2. Install dependencies
pnpm install

# 3a. Development mode
pnpm run dev

# 3b. Production mode
pnpm run build
pnpm start
```

Change `config/game.json` managerPassword before starting.

## Upgrade procedure

### Docker Compose

```bash
cd ~/rahoot
docker compose pull
docker compose up -d
```

Config volume persists across upgrades; quizzes and game settings are not affected.

### Manual / Node.js

```bash
cd Rahoot
git pull
pnpm install
pnpm run build
pnpm start
```

## Quiz management

Quizzes live in `config/quizz/*.json`. Two authoring methods:

1. **Built-in editor** — available in the manager dashboard at http://host:3000/manager (recommended).
2. **Manual JSON** — create files directly in `config/quizz/`. Each question supports 2-4 answer options, multi-correct solutions (array of 0-based indices), an optional media object (image, video, or audio URL), configurable cooldown (3-15 s), and answer time (5-120 s).

Example question:
```json
{
  "question": "Which of these are primary colors?",
  "answers": ["Red", "Green", "Blue", "Yellow"],
  "solutions": [0, 2, 3],
  "cooldown": 5,
  "time": 20
}
```

Select the active quiz and start a session from the manager dashboard, then share the game URL + room code with participants.

## Gotchas

- **Default manager password blocks access.** The default "PASSWORD" value is intentionally rejected — upstream blocks login when it detects the default. Edit `config/game.json` immediately after first run.
- **No TLS built in.** Rahoot exposes plain HTTP on port 3000. For public or LAN deployments, front it with a reverse proxy (Caddy, Nginx, Traefik) to terminate TLS.
- **Config volume must be persisted.** Without a bind-mount or named volume at `/app/config`, all quizzes and settings are lost on container restart.
- **Single-quiz selection.** Multiple quiz files can coexist in `config/quizz/`; select which one to play from the manager dashboard before starting a session.
- **Under active development.** The project self-describes as still in development — test before using for important events and pin a specific image tag in production (e.g. ralex91/rahoot:0.x.x) rather than latest.

## Links

- Upstream README: <https://github.com/Ralex91/Rahoot#readme>
- Docker image: <https://hub.docker.com/r/ralex91/rahoot>
- Issues / feedback: <https://github.com/Ralex91/Rahoot/issues>
