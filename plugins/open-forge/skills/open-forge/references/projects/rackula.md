---
name: Rackula
description: "Self-hosted drag-and-drop rack layout visualizer. Docker. GHCR. RackulaLives/Rackula. Plan and document server rack layouts with real device images; export PNG/PDF/SVG; QR code sharing; optional persistence."
---

# Rackula

**Drag-and-drop rack visualizer for planning and documenting server rack layouts.** Add real device images to a rack diagram; drag them around; export to PNG, PDF, or SVG for documentation. Layouts encode into the URL — share via QR code; no backend required for basic use. Optional self-hosted backend for persistent cross-session layout storage.

Built + maintained by **RackulaLives**. MIT license.

- Upstream repo: <https://github.com/RackulaLives/Rackula>
- Live instance: <https://count.racku.la>
- GHCR: `ghcr.io/rackulalives/rackula`

## Architecture in one minute

- Frontend-first: the layout lives in the URL (encoded) — works stateless
- Optional **backend API** for persistent named layouts (saved to server storage)
- GHCR Docker image: `ghcr.io/rackulalives/rackula`
- Port **8080**
- Two modes:
  1. **Stateless** (default) — layout in URL; no server-side storage
  2. **Persistent** (opt-in) — backend API + storage volume; layouts survive browser close
- Resource: **tiny** — static app + optional lightweight API

## Compatible install methods

| Infra       | Runtime                         | Notes                                       |
| ----------- | ------------------------------- | ------------------------------------------- |
| **Docker**  | `ghcr.io/rackulalives/rackula`  | **Primary** — GHCR                          |
| **Hosted**  | count.racku.la                  | Use directly in browser — no install needed |

## Install via Docker Run (stateless)

```bash
docker run -d -p 8080:8080 ghcr.io/rackulalives/rackula:latest
```

Visit `http://localhost:8080`.

## Install via Docker Compose

```bash
curl -O https://raw.githubusercontent.com/rackulalives/rackula/main/docker-compose.yml
docker compose up -d
```

## Install with persistent storage

```bash
git clone https://github.com/RackulaLives/Rackula.git
cd Rackula
curl -fsSL https://raw.githubusercontent.com/RackulaLives/Rackula/main/deploy/docker-compose.persist.yml -o docker-compose.yml
mkdir -p data
sudo chown 1001:1001 data
docker compose up -d
```

Full self-hosting guide: <https://github.com/RackulaLives/Rackula/blob/main/docs/guides/SELF-HOSTING.md>

## First boot (stateless)

1. Visit `http://localhost:8080`.
2. Drag devices from the left panel into the rack slots.
3. Device images are real hardware photos — it actually looks like your gear.
4. Add labels/notes per slot.
5. Export: PNG for screenshots, PDF for documentation, SVG for editing.
6. Share: the QR code button generates a scannable link — the entire layout is encoded in the URL.

## Production / persistent setup

For layouts that survive browser sessions and are shareable by name:

| Env variable | Default | Notes |
|---|---|---|
| `CORS_ORIGIN` | `*` | Set to your app URL to restrict API access |
| `RACKULA_API_WRITE_TOKEN` | unset | Protects PUT/DELETE API routes; strongly recommended |
| `RACKULA_AUTH_MODE` | `none` | `none` (open), `oidc`, or `local` |
| `RACKULA_AUTH_SESSION_SECRET` | — | Required when auth is enabled; min 32 chars |
| `RACKULA_AUTH_SESSION_COOKIE_SECURE` | `true` | Set `false` for HTTP-only local testing |

## Features overview

| Feature | Details |
|---------|---------|
| Drag-and-drop | Move devices freely within rack slots |
| Real device images | Hardware photos make diagrams look authentic |
| Export | PNG, PDF, SVG |
| URL encoding | Entire layout in URL — no server required for stateless sharing |
| QR code sharing | Generate QR code from current layout URL |
| Persistent storage | Optional backend API for named, server-saved layouts |
| Auth (opt-in) | OIDC or local login gate for persistent instance |

## Gotchas

- **Layouts in URL have size limits.** Very large/complex racks may exceed browser URL length limits (typically ~2000 chars for compatibility). For large racks, use persistent storage mode.
- **`data/` directory must be owned by UID 1001.** In persistent mode, the container runs as UID 1001. If the `data/` directory is owned by root, writes will fail. Run `sudo chown 1001:1001 data` before starting.
- **`RACKULA_API_WRITE_TOKEN` is strongly recommended for persistent mode.** Without it, anyone who can reach your instance can overwrite saved layouts. Set a random token.
- **Auth is still maturing.** Local auth mode is in progress (tracking issue #1117). OIDC is more stable. For a fully internal/trusted deployment, `RACKULA_AUTH_MODE=none` is fine.
- **No server needed for basic use.** If you just want to plan/document a rack and share via URL/QR code, use the live instance at count.racku.la or run the stateless Docker image. Persistent storage is only needed if you want layouts to survive browser sessions.
- **HTTPS required for `COOKIE_SECURE=true`.** In persistent mode with auth, cookies are set with Secure flag by default. You need HTTPS. Set `RACKULA_AUTH_SESSION_COOKIE_SECURE=false` only for local HTTP testing.

## Backup (persistent mode)

```sh
sudo tar czf rackula-$(date +%F).tgz data/
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active development, GHCR, PNG/PDF/SVG export, URL encoding, persistent storage option, OIDC auth. MIT license.

## Rack-visualization-family comparison

- **Rackula** — drag-and-drop, real device images, URL/QR sharing, export, optional persistence, MIT
- **Netbox** — Python, full DCIM with rack visualization + IP management + cable management; enterprise scope
- **RackTables** — PHP, older rack/IP management tool
- **draw.io / Lucidchart** — general diagramming; no rack-specific device library
- **Visio Rack Shapes** — Windows-only; not self-hosted

**Choose Rackula if:** you want a lightweight, good-looking drag-and-drop rack visualizer for planning or documenting rack layouts — with shareable URLs and no-install option.

## Links

- Repo: <https://github.com/RackulaLives/Rackula>
- Live: <https://count.racku.la>
- Self-hosting guide: <https://github.com/RackulaLives/Rackula/blob/main/docs/guides/SELF-HOSTING.md>
- GHCR: `ghcr.io/rackulalives/rackula`
