# Glass Keep

**What it is:** Self-hosted Google Keep alternative with a glassmorphism UI. Notes app supporting Markdown, checklists, drawing/handwritten notes, images, tags, dark/light mode, real-time collaboration, AI assistant (local Llama 3.2), PWA, import from Google Keep, and admin panel. Built with Vite + React frontend and Express + SQLite backend.

**GitHub:** https://github.com/nikunjsingh93/react-glass-keep

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Frontend + backend containers |
| Bare metal | Node.js | Build and run directly |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Host port | Port to expose the web UI |
| Admin credentials | Default admin: `admin` / `admin` — **change immediately** |

---

## Software-Layer Concerns

- **SQLite database** (`better-sqlite3`) — lightweight, single-file, no separate DB container
- **Express API** backend serves both the API and static frontend assets
- **Default admin account:** `admin` / `admin` — created automatically if no users exist; change on first login
- **New account creation is OFF by default** — enable in Admin Panel settings
- **Secret recovery key:** Generated at registration; download and store securely
- **Data directory:** Contains SQLite DB and uploaded images — persist this volume

### Feature highlights

| Feature | Notes |
|---------|-------|
| Note types | Text (Markdown), Checklists, Drawing/Handwritten |
| Images | Attach multiple; client-side compression; fullscreen viewer |
| Tags | Chip-based tags with sidebar filter |
| Collaboration | Real-time co-editing (checklists + notes) |
| AI assistant | Local Llama 3.2 (1B) — RAG over your notes; runs in Docker |
| Google Keep import | Import via Google Takeout `.json` files |
| Export | Export all notes as JSON; per-note `.md` download |
| PWA | Installable on desktop and mobile |
| Admin panel | User management, storage usage, toggle registration |
| Bulk actions | Select multiple notes to pin/delete/color/download |

### AI assistant requirements
- Runs a local Llama 3.2 (1B) model inside Docker
- Requires additional container with sufficient RAM (≥4 GB recommended)
- All AI inference is local — no external API calls

---

## Upgrade Procedure

1. Pull new image(s): `docker compose pull` (if using Docker)
2. Restart: `docker compose up -d`
3. For source installs: `git pull`, rebuild, restart

---

## Gotchas

- **Default `admin`/`admin` credentials** — change immediately after first login
- **New user registration is disabled by default** — enable via Admin Panel if needed
- **Secret recovery key** is shown once at registration — download it; losing it means no account recovery
- **Local AI assistant** requires a capable host — Llama 3.2 1B needs several GB RAM; disable if not needed
- No built-in HTTPS — reverse proxy required for internet-facing deployments
- Real-time collaboration uses WebSockets — ensure your reverse proxy passes WebSocket upgrades

---

## Links

- GitHub: https://github.com/nikunjsingh93/react-glass-keep
