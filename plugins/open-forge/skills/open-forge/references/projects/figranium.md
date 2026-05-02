---
name: figranium-project
description: Figranium recipe for open-forge. Self-hosted browser automation control plane. Block-based workflow builder with Playwright, task scheduling (cron), proxy management, API/CLI trigger, screenshot/recording captures, IP allowlists, audit trails. React/Vite frontend + Express/Playwright backend. Single container with noVNC. Upstream: https://github.com/figranium/figranium
---

# Figranium

A self-hosted browser automation control plane. Build block-based workflows (click, type, wait, hover, execute JavaScript) against live web pages using Playwright — no third-party SaaS, no data leaving your server. Schedule tasks with cron, trigger via HTTP API or CLI, manage proxies, capture screenshots/recordings, and enforce access control via IP allowlists and audit trails.

Ships with a noVNC viewer so you can watch browser automation live.

Upstream: <https://github.com/figranium/figranium>

Single container (React + Express + Playwright + noVNC). Multi-arch (AMD64 + ARM64/Apple Silicon).

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64) | Prebuilt image at `ghcr.io/figranium/figranium` |
| ARM64 / Apple Silicon | Build from source via `docker compose up --build` |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "App port?" | Default: `11345` — web UI |
| preflight | "VNC port?" | Default: `54311` — noVNC browser viewer |
| security | "SESSION_SECRET?" | Required — `openssl rand -hex 32` |

## Software-layer concerns

### Image

```
ghcr.io/figranium/figranium:latest
```

GitHub Container Registry. For ARM/Apple Silicon, build locally (see below).

### Compose (prebuilt image — AMD64)

```yaml
services:
  figranium:
    image: ghcr.io/figranium/figranium:latest
    container_name: figranium
    restart: unless-stopped
    ports:
      - "11345:11345"   # web UI
      - "54311:54311"   # noVNC viewer
    environment:
      - NODE_ENV=production
      - SESSION_SECRET=replace_with_long_random_value   # openssl rand -hex 32
    volumes:
      - ./data:/app/data
      - ./public:/app/public
```

### Compose (ARM / Apple Silicon — build from source)

```yaml
services:
  figranium:
    build: .
    ports:
      - "11345:11345"
      - "54311:54311"
    environment:
      - NODE_ENV=production
      - SESSION_SECRET=replace_with_long_random_value
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```

```bash
git clone https://github.com/figranium/figranium.git
cd figranium
docker compose up --build -d
```

> Source: upstream README — <https://github.com/figranium/figranium>

### Key environment variables

| Variable | Required | Purpose |
|---|---|---|
| `SESSION_SECRET` | ✅ | Signs session cookies — generate a long random value; do not share |
| `NODE_ENV` | — | Set to `production` for the container |

### Volumes

| Path | Purpose |
|---|---|
| `./data:/app/data` | Persistent storage: tasks, proxies, API keys, allowlists, config |
| `./public:/app/public` | Screenshots and recordings (captures tab) |

### First run

1. Navigate to `http://host:11345`
2. The first visit shows a setup/login screen — create your admin account
3. After login, the dashboard is the landing page for all future visits (until logout or session expiry)

### Task API

Saved tasks can be triggered via HTTP:

```bash
curl -X POST http://host:11345/tasks/:id/api \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"variable": "value"}'
```

API keys are managed in Settings → System.

### CLI

```bash
npx figranium --task <task-id> --key <api-key>
```

### noVNC

Watch live browser automation at `http://host:54311`. Useful for debugging workflows.

### IP allowlists

Restrict which IPs can access the web UI: Settings → System → IP Allowlists. Leave empty to allow all.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in `./data` and `./public` bind mounts.

## Gotchas

- **`SESSION_SECRET` is required** — without it sessions won't persist correctly or may be insecure. Generate once and store safely.
- **No prebuilt ARM image** — `ghcr.io/figranium/figranium` is AMD64 only. ARM users (including Apple Silicon running Linux VMs or Raspberry Pi) must build from source.
- **noVNC port (54311) should not be publicly exposed** — it gives a live view of the browser. Restrict to your LAN/VPN or close it entirely if you don't need live monitoring.
- **`./data` bind mount must exist** — create it before first run (`mkdir -p data public`) or Docker will create it as root.
- **Playwright bundles Chromium** — the container is larger than average (~1–2 GB) due to the bundled browser.
- **`scripts/postinstall.js` runs on install** — if you customize the image, be aware this script runs automatically when npm dependencies are installed.
- **Port 11345 should be behind auth/TLS if exposed** — consider fronting with Caddy or nginx with HTTPS and basic auth if accessible from the internet.

## Links

- Upstream README: <https://github.com/figranium/figranium>
