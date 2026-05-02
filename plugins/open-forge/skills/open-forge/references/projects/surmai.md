---
name: surmai
description: Recipe for Surmai — personal/family travel organizer. Collaborative trip planning with offline access. React SPA + PocketBase backend. Self-hosting via Docker per official docs.
---

# Surmai

Personal and family travel organizer for collaborative trip planning. Upstream: https://github.com/rohitkumbhar/surmai

React SPA (Mantine UI) + PocketBase backend. Organize trip artifacts (tickets, reservations, confirmations) chronologically, share with travel companions, and access offline via PWA. Privacy-focused — your data stays on your server.

Official installation docs: http://surmai.app/documentation/installation
Live demo: https://demo.surmai.app (demo@surmai.app / vi#c8Euuf16idhbG — cleaned hourly)

> **Alpha software** — actively developed, expect rough edges. Report issues on GitHub.

## Compatible combos

| Method | Notes |
|---|---|
| Docker (self-hosted) | Official method — see upstream installation guide |
| surmai.app (demo) | Ephemeral demo only — not for production data |

## Inputs to collect

Exact inputs depend on the current upstream Docker guide at http://surmai.app/documentation/installation

Typically:
| Phase | Prompt | Notes |
|---|---|---|
| preflight | Public URL / domain | Where Surmai will be accessible |
| preflight | Volume/data path | For PocketBase data persistence |
| smtp (opt) | SMTP settings | For user account emails (PocketBase admin UI) |

## Software-layer concerns

**Backend:** PocketBase — a single Go binary with embedded SQLite. Admin UI available for configuration not yet exposed in Surmai's own UI.

**Frontend:** React SPA built with Vite. PWA-installable on mobile via browser (Add to Home Screen).

**Data:** PocketBase SQLite database must be persisted via volume. Follow the backup solution documented in the upstream install guide.

**PocketBase Admin UI:** Available alongside Surmai for advanced config (user management, schema inspection). Check upstream docs for the admin URL.

**Offline access:** PWA support enables offline access on mobile after initial load.

**Translations:** Multi-language via react-i18next. Contribute translations at https://hosted.weblate.org/projects/surmai/frontend/

## Docker Compose

The upstream README delegates compose details to the official installation docs.

**Do not use a fabricated compose file.** Follow the current upstream guide at:
http://surmai.app/documentation/installation

The guide includes Docker setup and a recommended backup solution.

## Upgrade procedure

Follow the upgrade guidance in the upstream installation docs. Typical flow:

```bash
docker compose pull
docker compose up -d
```

Back up the PocketBase data volume before upgrading — PocketBase may run schema migrations on startup.

## Gotchas

- **Alpha software** — the project is under active development; APIs and data schema may change between versions.
- **PocketBase migrations on upgrade** — always back up the data volume before pulling a new image version.
- **PWA install varies by browser/OS** — iOS users install via Safari's "Add to Home Screen"; Android via Chrome.
- **Demo is cleaned hourly** — do not use the demo to store real travel data.

## Links

- Upstream repository: https://github.com/rohitkumbhar/surmai
- Installation guide: http://surmai.app/documentation/installation
- Screenshots: http://surmai.app/documentation/screenshots
- Demo: https://demo.surmai.app
- Translations: https://hosted.weblate.org/projects/surmai/frontend/
