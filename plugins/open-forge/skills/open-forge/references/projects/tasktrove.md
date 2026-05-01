---
name: TaskTrove
description: "Self-hosted minimalist GTD task manager. Docker. Go + SQLite. dohsimpson/TaskTrove. Inbox/Today/Upcoming/Someday, recurring tasks, tags, notes, CLI access, Org-Mode export/import, mobile-friendly. MIT."
---

# TaskTrove

**Minimalist self-hosted task manager inspired by GTD (Getting Things Done).** Capture tasks in an Inbox, review them into Today/Upcoming/Someday/Archive, set due dates, add tags and notes, create recurring tasks, and export to Org-Mode format. Clean and fast web UI; works on mobile. CLI access for terminal users. No bloat.

Built + maintained by **dohsimpson**. MIT license.

- Upstream repo: <https://github.com/dohsimpson/TaskTrove>
- Demo: <https://tasktrove-demo.up.railway.app>
- Docker Hub: `dohsimpson/tasktrove`

## Architecture in one minute

- **Go** binary backend + web frontend
- **SQLite** database (default, zero-config)
- Port **8080**
- Data volume: `./data`
- No external dependencies
- Resource: **tiny** — Go binary + SQLite

## Compatible install methods

| Infra      | Runtime                  | Notes                              |
| ---------- | ------------------------ | ---------------------------------- |
| **Docker** | `dohsimpson/tasktrove`   | **Primary** — Docker Hub           |

## Install via Docker Compose

```yaml
services:
  tasktrove:
    image: dohsimpson/tasktrove:latest
    container_name: tasktrove
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
    environment:
      - TZ=UTC
```

Visit `http://localhost:8080`.

## First boot

1. `docker compose up -d`.
2. Visit `http://localhost:8080`.
3. Capture a few tasks into the **Inbox**.
4. Process your inbox: move tasks to Today, Upcoming, or Someday.
5. Set due dates, add tags, write notes.
6. Mark complete as you finish tasks.
7. Put behind TLS.

## GTD workflow in TaskTrove

| View | Purpose |
|------|---------|
| **Inbox** | Capture everything here first (quick capture) |
| **Today** | Tasks to do today |
| **Upcoming** | Tasks with future due dates |
| **Someday** | Someday/Maybe list — aspirational but not scheduled |
| **Archive** | Completed and archived tasks |

## Features overview

| Feature | Details |
|---------|---------|
| Task capture | Quick add to Inbox; add to any view |
| Due dates | Set date/time per task; Upcoming view sorted by date |
| Recurring tasks | Daily, weekly, monthly, custom recurrence |
| Tags | Multi-tag; filter by tag |
| Notes | Rich notes per task (markdown) |
| Subtasks | Nested task structure |
| Priorities | Optional task priority levels |
| CLI access | TaskTrove exposes a CLI interface for terminal-based access |
| Org-Mode | Export tasks to Org-Mode format; import from Org-Mode |
| Mobile UI | Responsive; works on phone browsers |
| Keyboard shortcuts | Full keyboard navigation |
| Search | Full-text search across tasks |

## Org-Mode integration

TaskTrove can export and import tasks in **Emacs Org-Mode** format (`.org` files). Useful for:
- Backing up tasks in a readable plaintext format
- Migrating from/to Emacs-based task management (Org-Mode, Org-agenda)
- Archiving completed tasks in a text-based journal

## CLI access

TaskTrove provides a CLI for capturing and managing tasks without opening the browser. Useful for:
- Shell scripts that create tasks programmatically
- Quick capture from the terminal
- Automation workflows

## Gotchas

- **Single-user.** TaskTrove is designed as a personal task manager — one account, one person's tasks. No multi-user or team features.
- **SQLite for persistence.** Back up the `./data` directory — it contains your entire task database. Since it's SQLite, you can inspect and query it directly with any SQLite client.
- **GTD philosophy required.** TaskTrove's five-view model (Inbox/Today/Upcoming/Someday/Archive) is a GTD workflow. If you want traditional project-based task management (kanban boards, milestones), use Vikunja or Plane instead.
- **Minimal by design.** TaskTrove prioritizes simplicity over feature density. If you need time tracking, team collaboration, or advanced project management, use a different tool.
- **Recurring tasks.** For recurring tasks to generate properly, the TaskTrove service must be running. Missed recurring generation (e.g., server was down) may need manual recovery.

## Backup

```sh
sudo tar czf tasktrove-$(date +%F).tgz data/
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Go development, Docker Hub, CLI, Org-Mode, demo instance on Railway. Solo-maintained by dohsimpson. MIT license.

## Task-manager-family comparison

- **TaskTrove** — Go, GTD workflow, Inbox/Today/Upcoming/Someday, Org-Mode, CLI, MIT
- **Vikunja** — Go, full project + team management; much more feature-rich
- **Plane** — Python+React, GitHub Issues-like; project/sprint management
- **Super Productivity** — Angular, local-first, time tracking, GTD-adjacent; no self-hosted server
- **Tasks (caldav)** — CalDAV-based; relies on a CalDAV server
- **Todoist** — SaaS; the commercial GTD reference

**Choose TaskTrove if:** you practice GTD and want a clean, self-hosted, Go-powered personal task manager with Inbox, Today, Someday views, recurring tasks, Org-Mode export, and CLI access.

## Links

- Repo: <https://github.com/dohsimpson/TaskTrove>
- Demo: <https://tasktrove-demo.up.railway.app>
- Docker Hub: `dohsimpson/tasktrove`
