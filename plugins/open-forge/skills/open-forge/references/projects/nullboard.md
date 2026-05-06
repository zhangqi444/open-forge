---
name: nullboard
description: Nullboard recipe for open-forge. Minimalist single-file kanban board that runs entirely in the browser with localStorage. No server required; optional backup agent for local disk persistence. Source: https://github.com/apankrat/nullboard.
---

# Nullboard

Minimalist kanban board / task list manager implemented as a single HTML file. Runs entirely client-side using localStorage — no server, no database, no install. Data stays in the browser. Optional backup agents (Windows, Express.js, Python) can persist data to local disk. Upstream: <https://github.com/apankrat/nullboard>.

> **Note:** Nullboard is browser-local by design. It is not a multi-user collaborative tool — it's for personal task management on a single machine. "Self-hosting" means serving the HTML file from a web server for access across your own devices; data still lives in each browser's localStorage.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any web server | Static file (NGINX, Apache, Caddy) | Serve index.html; all logic is client-side |
| Local machine | Open HTML file directly in browser | Simplest; no web server needed |
| Local machine | Nullboard Agent (Windows) | Local disk backup via native Windows app |
| Any host | Nullboard Agent Express Port | node.js backup agent; cross-platform |
| Linux / macOS | nbagent (Python) | Python-based backup agent |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Direct file, web server, or with backup agent?" | Drives setup |
| backup | "Which backup agent? (Windows app / Express.js / Python / none)" | Optional; for persisting boards to disk |
| port | "Port to serve on (if using web server or backup agent)?" | Express agent default: 9000 |

## Software-layer concerns

- No server-side state: all board data lives in the browser's localStorage
- Export/import: boards can be exported to / imported from JSON text files
- Data loss risk: clearing browser data / localStorage wipes all boards. Use export or a backup agent for persistence.
- Backup agents expose a local HTTP endpoint that Nullboard can auto-backup to on every change
- No authentication: if served on a network, anyone who can reach the URL can access the board

### Serve with NGINX (Docker)

```yaml
services:
  nullboard:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./nullboard:/usr/share/nginx/html:ro
    restart: unless-stopped
```

```bash
git clone https://github.com/apankrat/nullboard.git
# Then run docker compose up -d and visit http://localhost:8080
```

### Serve directly (Python one-liner)

```bash
git clone https://github.com/apankrat/nullboard.git && cd nullboard
python3 -m http.server 8080
```

### Backup agent (Express.js — cross-platform)

```bash
git clone https://github.com/justinpchang/nullboard-agent-express.git
cd nullboard-agent-express && npm install
node index.js  # Default port 9000
```

In Nullboard settings, set backup URL to `http://localhost:9000`.

### Backup agent (Python/Linux — nbagent)

```bash
pip install nbagent
nbagent --port 9000 --dir ~/nullboard-backups
```

## Upgrade procedure

1. Pull new version: `git pull` in the nullboard directory
2. Refresh browser — no server restart needed (static files)

## Gotchas

- **localStorage is per-browser-per-origin**: Boards created in Chrome are not visible in Firefox, or at a different URL/port. Data is not shared across browsers or devices without export/import or a backup agent.
- **No multi-user support**: Nullboard is single-user by design. It has no authentication, no conflict resolution, and no real-time sync.
- **Beta status**: The project is explicitly in beta. Treat it as a personal convenience tool, not a production task tracker.
- **Backup agent required for persistence**: Without a backup agent, boards exist only in localStorage. A browser update, privacy mode, or data clear will wipe everything.
- **Network access without auth**: If you serve Nullboard on a network (not just localhost), anyone who can reach it sees your boards. Restrict with a reverse proxy auth layer (Authelia, HTTP basic auth, etc.) or use only on localhost.

## Links

- Upstream repo: https://github.com/apankrat/nullboard
- Live preview: https://nullboard.io/preview
- Nullboard Agent (Windows backup): https://nullboard.io/backups
- Express.js agent: https://github.com/justinpchang/nullboard-agent-express
- Python agent (nbagent): https://github.com/luismedel/nbagent
