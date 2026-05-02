# Manage My Damn Life (MMDL)

**What it is:** Self-hosted CalDAV task and calendar front end. Connect to any CalDAV server (Nextcloud, Baikal tested) to manage tasks with subtask support, rich fields (due dates, status, description, recurrence), calendar events, multiple accounts, Gantt view, and OAuth support.

**Official site:** https://intri.in/manage-my-damn-life/  
**Docs:** https://manage-my-damn-life-nextjs.readthedocs.io/en/latest/install/  
**GitHub:** https://github.com/intri-in/manage-my-damn-life-nextjs

> ⚠️ **Beta software** — take care when using with production CalDAV data.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended deployment |
| Bare metal | Node.js | Next.js app |

---

## Prerequisites

- A running **CalDAV server** — tested with Nextcloud and Baikal
- CalDAV basic auth credentials (OAuth for CalDAV not yet supported)

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| CalDAV server URL | URL of your Nextcloud / Baikal / CalDAV instance |
| CalDAV credentials | Username and password for basic auth |
| App port | Port to expose MMDL web UI |

### Phase: Optional

| Item | Description |
|------|-------------|
| OAuth provider | For MMDL user authentication (separate from CalDAV auth); see OAuth docs |
| Multiple CalDAV accounts | Multiple accounts can be added per MMDL user |

---

## Software-Layer Concerns

- **CalDAV authentication** — currently basic auth only; CalDAV OAuth not yet supported
- **Multiple user accounts** — each MMDL user can connect their own CalDAV accounts
- **Desktop-first design** — responsive but optimized for desktop; mobile CalDAV clients (JTX Boards, OpenTasks) recommended for mobile use
- **Task views:** list, Gantt, calendar
- **Filters:** create and save custom task filters
- **Translations:** managed via Weblate (community-contributed)

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Check release notes for any breaking config changes

---

## Gotchas

- **Beta software** — back up CalDAV data before use; behavior with production data is not guaranteed
- **Basic auth only for CalDAV** — servers requiring modern auth methods are not supported yet
- Compatibility confirmed with Nextcloud and Baikal; other CalDAV servers may work but are untested
- Desktop-first — the interface is not optimized for mobile browsers

---

## Links

- Website: https://intri.in/manage-my-damn-life/
- Docs: https://manage-my-damn-life-nextjs.readthedocs.io/en/latest/install/
- GitHub: https://github.com/intri-in/manage-my-damn-life-nextjs
- Translations: https://hosted.weblate.org/projects/mmdl-manage-my-damn-life/
